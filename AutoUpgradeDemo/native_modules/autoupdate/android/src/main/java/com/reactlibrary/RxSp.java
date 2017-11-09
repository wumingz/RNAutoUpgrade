package com.reactlibrary;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;

import java.util.Map;
import java.util.Set;

public class RxSp implements SharedPreferences, SharedPreferences.Editor {


    public final static String DEFAULT_PREFERENCE_NAME = "default.pref";
    private Context mContext;
    private SharedPreferences sp;
    private SharedPreferences.Editor editor;

    public RxSp(Context ctx) {
        this.mContext = ctx;
        this.sp = mContext.getSharedPreferences(DEFAULT_PREFERENCE_NAME, Activity.MODE_PRIVATE);
        editor = sp.edit();
    }

    public RxSp(Context ctx, String name) {
        this.mContext = ctx;
        this.sp = mContext.getSharedPreferences(name, Activity.MODE_PRIVATE);
        editor = sp.edit();
    }

    @Override
    public Map<String, ?> getAll() {
        return sp.getAll();
    }

    @Override
    public String getString(String key, String defValue) {
        return sp.getString(key, defValue);
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    @Override
    public Set<String> getStringSet(String key, Set<String> defValues) {
        return sp.getStringSet(key, defValues);
    }

    @Override
    public int getInt(String key, int defValue) {
        return sp.getInt(key, defValue);
    }

    @Override
    public long getLong(String key, long defValue) {
        return sp.getLong(key, defValue);
    }

    @Override
    public float getFloat(String key, float defValue) {
        return sp.getFloat(key, defValue);
    }

    @Override
    public boolean getBoolean(String key, boolean defValue) {
        return sp.getBoolean(key, defValue);
    }

    @Override
    public boolean contains(String key) {
        return sp.contains(key);
    }

    @Override
    public Editor edit() {
        return sp.edit();
    }

    @Override
    public void registerOnSharedPreferenceChangeListener(
            OnSharedPreferenceChangeListener listener) {
        // TODO Auto-generated method stub

    }

    @Override
    public void unregisterOnSharedPreferenceChangeListener(
            OnSharedPreferenceChangeListener listener) {
        // TODO Auto-generated method stub

    }

    @Override
    public Editor putString(String key, String value) {
        return edit().putString(key, value);
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    @Override
    public Editor putStringSet(String key, Set<String> values) {
        return edit().putStringSet(key, values);
    }

    @Override
    public Editor putInt(String key, int value) {
        return edit().putInt(key, value);
    }

    @Override
    public Editor putLong(String key, long value) {
        return edit().putLong(key, value);
    }

    @Override
    public Editor putFloat(String key, float value) {
        return edit().putFloat(key, value);
    }

    @Override
    public Editor putBoolean(String key, boolean value) {
        return edit().putBoolean(key, value);
    }

    @Override
    public Editor remove(String key) {
        return edit().remove(key);
    }

    @Override
    public Editor clear() {
        return edit().clear();
    }

    @Override
    public boolean commit() {
        return edit().commit();
    }

    @Override
    public void apply() {
        edit().apply();
    }
}
