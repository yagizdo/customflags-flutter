/// Client SDK for the CustomFlags feature-flag service.
///
/// Configure the SDK with a `CustomFlagConfig`, then read flag values
/// through the [Flag] API. Errors surface as subtypes of
/// [CustomFlagsException] so you can catch the whole SDK surface in
/// one place or handle specific failure modes individually.
library;

export 'src/core/exceptions.dart';
export 'src/core/models/flag_model.dart';
