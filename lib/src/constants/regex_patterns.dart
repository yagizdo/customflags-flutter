/// Matches CR, LF, NUL, and other ASCII control characters in the
/// `\x00`–`\x1f` range.
///
/// Used to sanitize untrusted strings (e.g. backend response bodies)
/// before they reach loggers — replacing matches with a space prevents
/// CWE-117 log injection, where a malicious `\n` could fake a new log
/// entry in line-oriented log aggregators.
final RegExp kLogInjectionControlCharsPattern = RegExp(r'[\r\n\x00-\x1f]');
