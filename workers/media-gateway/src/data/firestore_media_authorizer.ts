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
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${userId}/deliveries`,
    );
    url.searchParams.set("pageSize", "100");
    const readableIds = new Set<string>();
    const signal = AbortSignal.timeout(12000);
    const ownedIds = publicIds.filter((id) => id.startsWith(`inkstamp/${userId}/`));
    for (const ownedId of ownedIds) {
      // Owner prefix alone is insufficient after a sender revokes a stamp.
      const response = await fetch(
        `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
        { method: "POST", signal, headers: { Authorization: `Bearer ${idToken}`, "Content-Type": "application/json" },
          body: JSON.stringify({ structuredQuery: {
            from: [{ collectionId: "stamps" }],
            where: { compositeFilter: { op: "AND", filters: [
              { fieldFilter: { field: { fieldPath: "senderId" }, op: "EQUAL", value: { stringValue: userId } } },
              { fieldFilter: { field: { fieldPath: "status" }, op: "EQUAL", value: { stringValue: "active" } } },
              { fieldFilter: { field: { fieldPath: ownedId.includes('/thumbnail/') ? "cloudinaryThumbnailPublicId" : "cloudinaryPublicId" }, op: "EQUAL", value: { stringValue: ownedId } } },
            ] } },
            select: { fields: [{ fieldPath: "cloudinaryPublicId" }, { fieldPath: "cloudinaryThumbnailPublicId" }] },
            limit: 1,
          } }),
        },
      );
      if (!response.ok) return false;
      const documents = await response.json<ReadonlyArray<{ document?: FirestoreDocument }>>();
      for (const item of documents) addMediaIds(readableIds, item.document);
    }
    const visited = new Set<string>();
    while (!publicIds.every((id) => readableIds.has(id))) {
      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${idToken}` }, signal,
      });
      if (!response.ok) return false;
      const result = await response.json<FirestoreListResponse>();
      for (const document of result.documents ?? []) {
        if (document.fields?.status?.stringValue === "available") {
          addMediaIds(readableIds, document);
        }
      }
      if (!result.nextPageToken) break;
      if (visited.has(result.nextPageToken)) return false;
      visited.add(result.nextPageToken);
      url.searchParams.set("pageToken", result.nextPageToken);
    }
    return publicIds.every((publicId) => readableIds.has(publicId));
  }
}

interface FirestoreListResponse {
  readonly documents?: ReadonlyArray<FirestoreDocument>;
  readonly nextPageToken?: string;
}

interface FirestoreDocument {
  readonly fields?: Record<string, { readonly stringValue?: string }>;
}

function addMediaIds(ids: Set<string>, document?: FirestoreDocument): void {
  const full = document?.fields?.cloudinaryPublicId?.stringValue;
  const thumb = document?.fields?.cloudinaryThumbnailPublicId?.stringValue;
  if (full) ids.add(full);
  if (thumb) ids.add(thumb);
}
