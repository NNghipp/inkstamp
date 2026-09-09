export interface MediaAuthorizer {
  canRead(input: {
    idToken: string;
    projectId: string;
    publicIds: readonly string[];
    userId: string;
  }): Promise<boolean>;
}

export class FirestoreRestMediaAuthorizer implements MediaAuthorizer {
  async canRead({ idToken, projectId, publicIds, userId }: {
    idToken: string;
    projectId: string;
    publicIds: readonly string[];
    userId: string;
  }): Promise<boolean> {
    if (publicIds.every((publicId) => publicId.startsWith(`inkstamp/${userId}/`))) {
      return true;
    }

    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}/deliveries`,
    );
    url.searchParams.set("pageSize", "100");
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${idToken}` },
    });
    if (!response.ok) return false;

    const result = await response.json<FirestoreListResponse>();
    const readableIds = new Set<string>();
    for (const document of result.documents ?? []) {
      const stampId = document.fields?.cloudinaryPublicId?.stringValue;
      const thumbnailId =
        document.fields?.cloudinaryThumbnailPublicId?.stringValue;
      if (stampId) readableIds.add(stampId);
      if (thumbnailId) readableIds.add(thumbnailId);
    }
    return publicIds.every((publicId) => readableIds.has(publicId));
  }
}

interface FirestoreListResponse {
  readonly documents?: ReadonlyArray<{
    readonly fields?: Record<string, { readonly stringValue?: string }>;
  }>;
}
