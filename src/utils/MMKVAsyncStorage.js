import { createMMKV } from 'react-native-mmkv';

const storage = new createMMKV();

function isPlainObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function deepMerge(target, source) {
    if (!isPlainObject(target) || !isPlainObject(source)) {
        return source;
    }

    const merged = { ...target };

    Object.keys(source).forEach((key) => {
        const sourceValue = source[key];
        const targetValue = merged[key];

        merged[key] = isPlainObject(targetValue) && isPlainObject(sourceValue)
            ? deepMerge(targetValue, sourceValue)
            : sourceValue;
    });

    return merged;
}

function parseJson(value) {
    return value == null ? null : JSON.parse(value);
}

function invokeCallback(callback, ...args) {
    if (typeof callback === 'function') {
        callback(...args);
    }
}

const MMKVAsyncStorage = {
    async getItem(key, callback) {
        try {
            const value = storage.getString(key);
            const result = value ?? null;
            invokeCallback(callback, null, result);
            return result;
        } catch (error) {
            invokeCallback(callback, error, null);
            throw error;
        }
    },

    async setItem(key, value, callback) {
        try {
            storage.set(key, value);
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, error);
            throw error;
        }
    },

    async removeItem(key, callback) {
        try {
            storage.delete(key);
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, error);
            throw error;
        }
    },

    async mergeItem(key, value, callback) {
        try {
            const existingValue = storage.getString(key);

            if (existingValue == null) {
                storage.set(key, value);
                invokeCallback(callback, null);
                return;
            }

            const mergedValue = JSON.stringify(
                deepMerge(parseJson(existingValue), parseJson(value))
            );

            storage.set(key, mergedValue);
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, error);
            throw error;
        }
    },

    async clear(callback) {
        try {
            storage.clearAll();
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, error);
            throw error;
        }
    },

    async getAllKeys(callback) {
        try {
            const keys = storage.getAllKeys();
            invokeCallback(callback, null, keys);
            return keys;
        } catch (error) {
            invokeCallback(callback, error, null);
            throw error;
        }
    },

    async multiGet(keys, callback) {
        try {
            const result = keys.map((key) => [key, storage.getString(key) ?? null]);
            invokeCallback(callback, null, result);
            return result;
        } catch (error) {
            invokeCallback(callback, [error], null);
            throw error;
        }
    },

    async multiSet(keyValuePairs, callback) {
        try {
            keyValuePairs.forEach(([key, value]) => {
                storage.set(key, value);
            });
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, [error]);
            throw error;
        }
    },

    async multiRemove(keys, callback) {
        try {
            keys.forEach((key) => {
                storage.delete(key);
            });
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, [error]);
            throw error;
        }
    },

    async multiMerge(keyValuePairs, callback) {
        try {
            await Promise.all(
                keyValuePairs.map(([key, value]) => this.mergeItem(key, value))
            );
            invokeCallback(callback, null);
        } catch (error) {
            invokeCallback(callback, [error]);
            throw error;
        }
    },

    flushGetRequests() {}
};

export default MMKVAsyncStorage;