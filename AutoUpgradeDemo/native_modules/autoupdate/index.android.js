import {NativeModules, Platform, NativeAppEventEmitter, Alert,} from 'react-native';
const {RNAutoupgrade} = NativeModules;
export const APPVERSION = RNAutoupgrade.packageVersion;
export const LASTBUNDLEVERION = RNAutoupgrade.currentVersion;
export const APPVERSIONUPDATED = RNAutoupgrade.appVersionUpdated;
export const CURRENTBUNDLEVERSION = RNAutoupgrade.currentBundleVersion;
export const isFirstTime = RNAutoupgrade.isFirstTime;
export const isRolledBack = RNAutoupgrade.isRolledBack;
const API_DEFINE = 'http://10.8.75.86:3000/api/deployment/?';


function AlertDebug(title, message) {
    Alert.alert(title || "提示", message || '');
}

export default class RNAutoupgradeTool {

    constructor() {
        this.appkey = '';
        //标记是否正在请求版本更新
        this.isDownloading = false;
    }


    static async checkAutoUpgradeWithAppkey(appKey) {
        if (!appKey) {
            console.log("没有appkey");
            return;
        }
        if (this.isDownloading === true) {
            AlertDebug("提示", '正在检测中 ..');
            return;
        }
        this.isDownloading = true;
        this.appkey = appKey;
        console.log('====checkAutoUpgrade==');
        const CHECKUPDATEURL = API_DEFINE + `appKey=${appKey}&appVersion=${APPVERSION}&lastBundleVersion=${CURRENTBUNDLEVERSION || '0'}`;
        try {
            let response = await fetch(CHECKUPDATEURL, {
                method: 'GET',
                header: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                }
            });

            if (response.ok) {
                responseData = await response.json();
                console.log("===check update responseData=======", responseData);
                if (responseData.code === "0000") {
                    return await this.downloadUpgrade(responseData.data)
                        .then(() => {
                            this.alertSwitchVersion(responseData.data);
                            this.isDownloading = false;
                            console.log('===下载成功======', responseData.data.bundleJsMd5);
                            AlertDebug("提示", "自动更新下载完成！");
                        }).catch((error) => {
                            this.isDownloading = false;
                            console.log('=======downloadUpgrade callback=======', error);
                            AlertDebug("提示", "自动更新下载失败！");
                        });
                } else {
                    this.isDownloading = false;
                    AlertDebug("提示", "暂无版本更新数据！");
                }
            } else {
                this.isDownloading = false;
                AlertDebug("提示", "自动更新接口报错！");
            }
        } catch (err) {
            this.isDownloading = false;
            console.log("===check update err=======", err);
            AlertDebug("提示", "自动更新请求异常！");
        }
    }


    static async upgradeReport(status) {
        // const parmas = {'appKey': this.appkey, 'appVersion': APPVERSION, 'lastVersion': LASTBUNDLEVERION, 'status': status};
        // // await post(REPORT_UPDATE, parmas)
        // //     .then((response) => {
        // //
        // //     }, (response) => {
        // //
        // //     }).catch((error) => {
        // //
        // //     });
        //
        // await fetch(API_DEFINE + '/report',{
        //     method:'POST',
        //     header: {
        //         'Accept': 'application/json',
        //         'Content-Type': 'application/json',
        //     }})
        //     .then((response) => {
        //         if (response.code === '0000' && response.data) {
        //             Toast.show('更新报告success');
        //         }
        //     }, (response) => {
        //         Toast.show('更新报告false');
        //     }).catch((error) => {
        //         Toast.show('更新报告false');
        //     });

    }


    static async downloadUpgrade(data) {
        if (!data.downloadUrl || !data.downloadUrl.length) return;
        if (!data.isPatch) {
            return await this.downloadFullPackage(data);
        } else if (!APPVERSIONUPDATED || APPVERSIONUPDATED != APPVERSION) {
            //hashName:新包版本Hash，唯一且不同于其他版本号
            return await this.downloadPatchFromPackage(data);
        } else {
            return await this.downloadPatchFromPpk(data);
        }
    }


    //下载全包，替换旧版本
    static downloadFullPackage(data) {
        return RNAutoupgrade.downloadFullPackage({
            updateUrl: data.downloadUrl,
            hashName: data.bundleJsMd5,
        })
    }

    //第一次下载热更新差异包
    static downloadPatchFromPackage(data) {
        return RNAutoupgrade.downloadPatchFromPackage({
            updateUrl: data.downloadUrl,
            hashName: data.bundleJsMd5,
        })
    }


    //下载热更新迭代差异包
    static downloadPatchFromPpk(data) {
        return RNAutoupgrade.downloadPatchFromPpk({
            updateUrl: data.downloadUrl,
            hashName: data.bundleJsMd5,
            originHashName: LASTBUNDLEVERION,
        })
    }


    //是否提示用户重启app
    static alertSwitchVersion(data) {
        switch (data.updateType) {
            case 1:
                //更新后不提示
                RNAutoupgrade.setNeedUpdate({hashName: data.bundleJsMd5, currentBundleVersion: data.bundleV});
                break;
            case 2:
                //更新后提示
                Alert.alert('提示', data.description || '您有新的更新,是否立即使用?', [{
                    text: '立即使用', onPress: () => {
                        RNAutoupgrade.reloadUpdate({hashName: data.bundleJsMd5, currentBundleVersion: data.bundleV})
                    }
                }, {
                    text: '下次启动使用', onPress: () => {
                        RNAutoupgrade.setNeedUpdate({hashName: data.bundleJsMd5, currentBundleVersion: data.bundleV})
                    }
                }]);
                break;
            case 3:
                //更新后直接重启
                RNAutoupgrade.reloadUpdate({hashName: data.bundleJsMd5, currentBundleVersion: data.bundleV});
                break;

            default:
                break;
        }
    }


    //标记更新成功
    static markSuccess() {
        RNAutoupgrade.markSuccess();
    }


    //监听下载进度
    static addUpgradeDownloadProgress(callBack) {
        NativeAppEventEmitter.addListener('RCTHotUpdateDownloadProgress', (params) => {
            callBack(params);
            // if (!params.received || !params.total) return;
            // Toast.show('已下载文件：'+`${params.received*100/params.total}`+'%');
        })
    }


    //监听解压进度
    static addUpgradeUnzipProgress(callBack) {
        NativeAppEventEmitter.addListener('RCTHotUpdateUnzipProgress', (params) => {
            callBack(params);
            // if (!params.received || !params.total) return;
            // Toast.show('已解压文件：' + `${params.received * 100 / params.total}` + '%');
        })
    }


}

