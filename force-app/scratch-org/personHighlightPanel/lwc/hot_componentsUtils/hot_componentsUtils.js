export function resolve(path, obj) {
    if (typeof path !== 'string') {
        throw new Error('Path must be a string');
    }

    return path.split('.').reduce(function (prev, curr) {
        return prev ? prev[curr] : null;
    }, obj || {});
}
