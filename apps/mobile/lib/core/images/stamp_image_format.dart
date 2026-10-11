/// Versioned asset identity, not an authorization signal. Legacy IDs stay valid.
const stampImageSuffix = '_stamp_v1';

bool isProcessedStampImage(String? value) =>
    value != null &&
    (value.endsWith(stampImageSuffix) ||
        value.endsWith('$stampImageSuffix.png'));
