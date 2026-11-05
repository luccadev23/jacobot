/** `path` names the field that is wrong, like `item.text`. It never contains a value from the input. */
export interface ParseError { readonly path: string }
export type ParseResult<T> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly error: ParseError };

export const fail = (path: string): { readonly ok: false; readonly error: ParseError } => ({ ok: false, error: { path } });
export const pass = <T>(value: T): ParseResult<T> => ({ ok: true, value });

export type JsonValue = null | boolean | number | string | readonly JsonValue[] | { readonly [key: string]: JsonValue };
export type JsonObject = { readonly [key: string]: JsonValue };

export function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

export function isJsonValue(value: unknown, depth = 0): value is JsonValue {
  if (depth > 32) return false;
  if (value === null || typeof value === "string" || typeof value === "boolean") return true;
  if (typeof value === "number") return Number.isFinite(value);
  if (Array.isArray(value)) return value.every((item) => isJsonValue(item, depth + 1));
  return isPlainObject(value) && Object.values(value).every((item) => isJsonValue(item, depth + 1));
}

/** True when `record` has exactly the keys in `required` plus any of `optional`. */
export function hasKeys(record: Record<string, unknown>, required: readonly string[], optional: readonly string[] = []): string | undefined {
  for (const key of required) if (!Object.hasOwn(record, key)) return key;
  for (const key of Object.keys(record)) if (!required.includes(key) && !optional.includes(key)) return "";
  return undefined;
}
