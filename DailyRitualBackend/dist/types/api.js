export function ok(data, message) {
    return { success: true, data, ...(message ? { message } : {}) };
}
export function fail(message, code, details) {
    return { success: false, error: { error: 'Error', message, code, details } };
}
//# sourceMappingURL=api.js.map