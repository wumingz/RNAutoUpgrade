package com.reactlibrary;

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Environment;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;


/**
 * Environment.getDataDirectory() = /data
 * Environment.getDownloadCacheDirectory() = /cache
 * Environment.getExternalStorageDirectory() = /mnt/sdcard
 * Environment.getExternalStoragePublicDirectory(“test”) = /mnt/sdcard/test
 * Environment.getRootDirectory() = /system
 * getPackageCodePath() = /data/app/com.my.app-1.apk
 * getPackageResourcePath() = /data/app/com.my.app-1.apk
 * getCacheDir() = /data/data/com.my.app/cache
 * getDatabasePath(“test”) = /data/data/com.my.app/databases/test
 * getDir(“test”, Context.MODE_PRIVATE) = /data/data/com.my.app/app_test
 * getExternalCacheDir() = /mnt/sdcard/Android/data/com.my.app/cache
 * getExternalFilesDir(“test”) = /mnt/sdcard/Android/data/com.my.app/files/test
 * getExternalFilesDir(null) = /mnt/sdcard/Android/data/com.my.app/files
 * getFilesDir() = /data/data/com.my.app/files
 */

public class RxFileUtils {


    private static RxFileUtils sIns;
    public static final int SIZETYPE_B = 1;// 获取文件大小单位为B的double值
    public static final int SIZETYPE_KB = 2;// 获取文件大小单位为KB的double值
    public static final int SIZETYPE_MB = 3;// 获取文件大小单位为MB的double值
    public static final int SIZETYPE_GB = 4;// 获取文件大小单位为GB的double值
    public final static int MAX_LOG_FILE_LENTH = 20 * 1024 * 1024;
    private Context ctx;
    private final static String TAG = "RxFileUtils";
    private PackageManager pm;
    private String packageName;
    private String packResourcePath;
    public static String INTERNAL_CACHE_ROOT;
    public static final String SDCARD_ROOT = "Android/data/PKG/";
    public static final String DIR_DSPUSH_ROOT = SDCARD_ROOT + "dsAutoUpgrade";
    private static final int WRITE_BUFFER_SIZE = 1024 * 8;

    private RxFileUtils(Context ctx) {
        this.ctx = ctx;
        pm = this.ctx.getPackageManager();
        packageName = ctx.getPackageName();
        packResourcePath = ctx.getPackageResourcePath();
        INTERNAL_CACHE_ROOT = ctx.getCacheDir().getAbsolutePath();
    }

    public static RxFileUtils get(Context ctx) {
        synchronized (RxFileUtils.class) {
            if (sIns == null && ctx != null) {
                sIns = new RxFileUtils(ctx.getApplicationContext());
            } else if (sIns == null && ctx == null) {
                throw new NullPointerException("Context params can not be Null!");
            }
            return sIns;
        }
    }


    public boolean isSDCardMount() {
        return Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED);
    }

    public File getSDCardRootFile() {
        if (isSDCardMount()) {
            return Environment.getExternalStorageDirectory();
        }
        return null;
    }

    public String getSDCardRoot() {
        if (isSDCardMount()) {
            return Environment.getExternalStorageDirectory().getAbsolutePath();
        }
        return "";
    }


    // a/b/c , tmp/file
    public File getExpectDirSDCard(String... path) {
        if (!isSDCardMount() || path == null || path.length == 0)
            return null;
        File file = null;
        StringBuffer sBuffer = new StringBuffer();
        for (String tmpStr : path) {
            tmpStr = tmpStr.replaceAll("PKG", packageName);
            sBuffer.append(tmpStr + "/");
        }
        file = new File(getSDCardRoot(), sBuffer.toString());
        if (!file.exists()) {
            file.mkdirs();
        }
        File tmpFile = null;
        try {
            tmpFile = new File(file, ".nomedia");
            if (!tmpFile.exists()) {
                tmpFile.createNewFile();
                Log.i(TAG, "Success create file: " + tmpFile.getAbsolutePath());
            }
        } catch (IOException e) {
            Log.e(TAG, "Error create file: " + tmpFile.getAbsolutePath(), e);
        }
        return file;
    }

    public String getExpectPathSDCard(String... path) {
        File file = getExpectDirSDCard(path);
        if (file != null)
            return file.getAbsolutePath();
        return "";
    }

    public File getExpectFileSDCard(boolean create, String fileName, String... path) {
        File file = getExpectDirSDCard(path);
        File targetFile = null;
        if (file != null) {
            targetFile = new File(file, fileName);
            if (create) {
                if (!targetFile.exists()) {
                    try {
                        targetFile.createNewFile();
                    } catch (IOException e) {
                        e.printStackTrace();
                        Log.e(TAG, "Error create file: " + targetFile.getAbsolutePath(), e);
                    }
                }
            }
        }
        return targetFile;
    }


    public static String appendPathComponent(String basePath, String appendPathComponent) {
        return new File(basePath, appendPathComponent).getAbsolutePath();
    }

    public static void copyDirectoryContents(String sourceDirectoryPath, String destinationDirectoryPath) throws IOException {
        File sourceDir = new File(sourceDirectoryPath);
        File destDir = new File(destinationDirectoryPath);
        if (!destDir.exists()) {
            destDir.mkdir();
        }

        for (File sourceFile : sourceDir.listFiles()) {
            if (sourceFile.isDirectory()) {
                copyDirectoryContents(
                        appendPathComponent(sourceDirectoryPath, sourceFile.getName()),
                        appendPathComponent(destinationDirectoryPath, sourceFile.getName()));
            } else {
                File destFile = new File(destDir, sourceFile.getName());
                FileInputStream fromFileStream = null;
                BufferedInputStream fromBufferedStream = null;
                FileOutputStream destStream = null;
                byte[] buffer = new byte[WRITE_BUFFER_SIZE];
                try {
                    fromFileStream = new FileInputStream(sourceFile);
                    fromBufferedStream = new BufferedInputStream(fromFileStream);
                    destStream = new FileOutputStream(destFile);
                    int bytesRead;
                    while ((bytesRead = fromBufferedStream.read(buffer)) > 0) {
                        destStream.write(buffer, 0, bytesRead);
                    }
                } finally {
                    try {
                        if (fromFileStream != null) fromFileStream.close();
                        if (fromBufferedStream != null) fromBufferedStream.close();
                        if (destStream != null) destStream.close();
                    } catch (IOException e) {
                        throw new IOException("Error closing IO resources.", e);
                    }
                }
            }
        }
    }

    public static void deleteDirectoryAtPath(String directoryPath) {
        if (directoryPath == null) {
            Log.d(TAG, "deleteDirectoryAtPath attempted with null directoryPath");
            return;
        }
        File file = new File(directoryPath);
        if (file.exists()) {
            deleteFileOrFolderSilently(file);
        }
    }

    public static void deleteFileAtPathSilently(String path) {
        deleteFileOrFolderSilently(new File(path));
    }

    public static void deleteFileOrFolderSilently(File file) {
        if (file.isDirectory()) {
            File[] files = file.listFiles();
            for (File fileEntry : files) {
                if (fileEntry.isDirectory()) {
                    deleteFileOrFolderSilently(fileEntry);
                } else {
                    fileEntry.delete();
                }
            }
        }

        if (!file.delete()) {
            Log.d(TAG, "Error deleting file " + file.getName());
        }
    }

    public static boolean fileAtPathExists(String filePath) {
        return new File(filePath).exists();
    }

    public static void moveFile(File fileToMove, String newFolderPath, String newFileName) throws Exception {
        File newFolder = new File(newFolderPath);
        if (!newFolder.exists()) {
            newFolder.mkdirs();
        }

        File newFilePath = new File(newFolderPath, newFileName);
        if (!fileToMove.renameTo(newFilePath)) {
            throw new Exception("Unable to move file from " +
                    fileToMove.getAbsolutePath() + " to " + newFilePath.getAbsolutePath() + ".");
        }
    }

    public static String readFileToString(String filePath) throws IOException {
        FileInputStream fin = null;
        BufferedReader reader = null;
        try {
            File fl = new File(filePath);
            fin = new FileInputStream(fl);
            reader = new BufferedReader(new InputStreamReader(fin));
            StringBuilder sb = new StringBuilder();
            String line = null;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
            return sb.toString();
        } finally {
            if (reader != null) reader.close();
            if (fin != null) fin.close();
        }
    }

    public static void unzipFile(File zipFile, String destination) throws IOException {
        FileInputStream fileStream = null;
        BufferedInputStream bufferedStream = null;
        ZipInputStream zipStream = null;
        try {
            fileStream = new FileInputStream(zipFile);
            bufferedStream = new BufferedInputStream(fileStream);
            zipStream = new ZipInputStream(bufferedStream);
            ZipEntry entry;

            File destinationFolder = new File(destination);
            if (destinationFolder.exists()) {
                deleteFileOrFolderSilently(destinationFolder);
            }

            destinationFolder.mkdirs();

            byte[] buffer = new byte[WRITE_BUFFER_SIZE];
            while ((entry = zipStream.getNextEntry()) != null) {
                String fileName = entry.getName();
                File file = new File(destinationFolder, fileName);
                if (entry.isDirectory()) {
                    file.mkdirs();
                } else {
                    File parent = file.getParentFile();
                    if (!parent.exists()) {
                        parent.mkdirs();
                    }

                    FileOutputStream fout = new FileOutputStream(file);
                    try {
                        int numBytesRead;
                        while ((numBytesRead = zipStream.read(buffer)) != -1) {
                            fout.write(buffer, 0, numBytesRead);
                        }
                    } finally {
                        fout.close();
                    }
                }
                long time = entry.getTime();
                if (time > 0) {
                    file.setLastModified(time);
                }
            }
        } finally {
            try {
                if (zipStream != null) zipStream.close();
                if (bufferedStream != null) bufferedStream.close();
                if (fileStream != null) fileStream.close();
            } catch (IOException e) {
                throw new IOException("Error closing IO resources.", e);
            }
        }
    }

    public static void writeStringToFile(String content, String filePath) throws IOException {
        PrintWriter out = null;
        try {
            out = new PrintWriter(filePath);
            out.print(content);
        } finally {
            if (out != null) out.close();
        }
    }

    /**
     * Serializable
     *
     * @param fileName
     * @return
     * @throws IOException
     * @throws ClassNotFoundException
     */
    public Object loadObject(File saveFile, String fileName) throws IOException, ClassNotFoundException {
        File temp = saveFile;
        FileInputStream fin = null;
        ObjectInputStream oin = null;
        try {
            if (temp != null // <BR>
                    && temp.isFile() // <BR>
                    && temp.exists() // <BR>
                    && temp.length() > 0) {
                fin = new FileInputStream(temp);
                oin = new ObjectInputStream(fin);
                return oin.readObject();
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (fin != null) {
                    fin.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            try {
                if (oin != null) {
                    oin.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * @param fileName
     * @param obj
     * @throws IOException
     */
    public void saveObject(File saveFile, String fileName, Object obj) throws IOException {
        File file = saveFile;
        FileOutputStream fout = null;
        ObjectOutputStream oout = null;
        try {
            fout = new FileOutputStream(file);
            oout = new ObjectOutputStream(fout);
            oout.writeObject(obj);
            oout.flush();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (oout != null) {
                    oout.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            try {
                if (fout != null) {
                    fout.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Load Object from String where get from file .
     *
     * @return
     * @throws Exception
     */
    public String loadJSONString(File saveFile, String fileName) throws Exception {
        BufferedReader bufferedReader = null;
        InputStream in = null;
        try {
            File file = saveFile;
            in = new FileInputStream(file);
            bufferedReader = new BufferedReader(new InputStreamReader(in));
            StringBuilder stringBuilder = new StringBuilder();
            String line = null;
            while ((line = bufferedReader.readLine()) != null) {
                stringBuilder.append(line);
            }
            return stringBuilder.toString();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (bufferedReader != null) {
                    bufferedReader.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            try {
                if (in != null) {
                    in.close();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    /**
     * @param JSONString
     * @param fileName
     * @return
     */
    public boolean saveJSONString(File saveFile, String JSONString, String fileName) {
        if (JSONString == null || JSONString.isEmpty())
            return false;
        Writer writer = null;
        OutputStream out = null;
        try {
            File file = saveFile;
            out = new FileOutputStream(file);
            writer = new OutputStreamWriter(out);
            writer.write(JSONString);
            writer.flush();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (writer != null) {
                try {
                    writer.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
            }
            if (out != null)
                try {
                    out.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
        }
        return false;
    }
}
