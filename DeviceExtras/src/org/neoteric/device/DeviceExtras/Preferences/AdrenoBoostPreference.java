/*
* Copyright (C) 2016 The OmniROM Project
* Copyright (C) 2021-2022 The Evolution X Project
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.com/licenses/>.
*
*/
package org.neoteric.device.DeviceExtras;

import android.content.Context;
import android.content.SharedPreferences;
import androidx.preference.PreferenceManager;
import androidx.preference.PreferenceViewHolder;
import android.util.AttributeSet;

import org.neoteric.device.DeviceExtras.DeviceExtras;
import org.neoteric.device.DeviceExtras.FileUtils;

import org.neoteric.support.preference.CustomSeekBarPreference;

public class AdrenoBoostPreference extends CustomSeekBarPreference {

    private static int mMinVal = 0;
    private static int mMaxVal = 3;
    private static int mDefVal = 0;

    private static final String FILE = "/sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost";

    public AdrenoBoostPreference(Context context, AttributeSet attrs) {
        super(context, attrs);

        mInterval = 1;
        mShowSign = false;
        mUnits = "";
        mContinuousUpdates = false;

        mMinValue = mMinVal;
        mMaxValue = mMaxVal;
        mDefaultValueExists = true;
        mDefaultValue = mDefVal;
        mValue = Integer.parseInt(loadValue());

        setPersistent(false);
    }

    public static boolean isSupported() {
        return FileUtils.fileWritable(FILE);
    }

    public static void restore(Context context) {
        if (!isSupported()) {
            return;
        }

        String storedValue = PreferenceManager.getDefaultSharedPreferences(context).getString(DeviceExtras.KEY_ADRENOBOOST, String.valueOf(mDefVal));
        FileUtils.writeValue(FILE, storedValue);
    }
    
    public static String loadValue() {
        return FileUtils.getFileValue(FILE, String.valueOf(mDefVal));
    }

    private void saveValue(String newValue) {
        FileUtils.writeValue(FILE, newValue);
        SharedPreferences.Editor editor = PreferenceManager.getDefaultSharedPreferences(getContext()).edit();
        editor.putString(DeviceExtras.KEY_ADRENOBOOST, newValue);
        editor.apply();
    }

    @Override
    protected void changeValue(int newValue) {
        saveValue(String.valueOf(newValue));
    }
}
