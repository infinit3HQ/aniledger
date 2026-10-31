//
//  GraphQLMutations.swift
//  AniLedger
//
//  Created by Niraj Dilshan on 10/13/2025.
//

import Foundation

struct UpdateProgressMutation: GraphQLMutation {
    let mediaId: Int
    let progress: Int
    let status: String?
    
    var mutationString: String {
        """
        mutation ($mediaId: Int, $progress: Int, $status: MediaListStatus) {
          SaveMediaListEntry(mediaId: $mediaId, progress: $progress, status: $status) {
            id
            progress
            status
            media {
              id
            }
          }
        }
        """
    }
    
    var variables: [String: Any] {
        var vars: [String: Any] = [
            "mediaId": mediaId,
            "progress": progress
        ]
        if let status = status {
            vars["status"] = status
        }
        return vars
    }
}

struct UpdateStatusMutation: GraphQLMutation {
    let mediaId: Int
    let status: String
    
    var mutationString: String {
        """
        mutation ($mediaId: Int, $status: MediaListStatus) {
          SaveMediaListEntry(mediaId: $mediaId, status: $status) {
            id
            status
            media {
              id
            }
          }
        }
        """
    }
    
    var variables: [String: Any] {
        [
            "mediaId": mediaId,
            "status": status
        ]
    }
}

struct UpdateScoreMutation: GraphQLMutation {
    let mediaId: Int
    let score: Double
    
    var mutationString: String {
        """
        mutation ($mediaId: Int, $score: Float) {
          SaveMediaListEntry(mediaId: $mediaId, score: $score) {
            id
            score
            media {
              id
            }
          }
        }
        """
    }
    
    var variables: [String: Any] {
        [
            "mediaId": mediaId,
            "score": score
        ]
    }
}

struct DeleteMediaListEntryMutation: GraphQLMutation {
    let id: Int
    
    var mutationString: String {
        """
        mutation ($id: Int) {
          DeleteMediaListEntry(id: $id) {
            deleted
          }
        }
        """
    }
    
    var variables: [String: Any] {
        ["id": id]
    }
}

/// Saves any combination of status, progress and score in one request.
/// Used by the sync queue so that several offline edits to the same entry
/// are pushed together instead of overwriting each other.
struct SaveMediaListEntryMutation: GraphQLMutation {
    let mediaId: Int
    let status: String?
    let progress: Int?
    let score: Double?
    
    var mutationString: String {
        """
        mutation ($mediaId: Int, $status: MediaListStatus, $progress: Int, $score: Float) {
          SaveMediaListEntry(mediaId: $mediaId, status: $status, progress: $progress, score: $score) {
            id
            status
            progress
            score
            media {
              id
            }
          }
        }
        """
    }
    
    var variables: [String: Any] {
        var vars: [String: Any] = ["mediaId": mediaId]
        if let status = status { vars["status"] = status }
        if let progress = progress { vars["progress"] = progress }
        if let score = score { vars["score"] = score }
        return vars
    }
}
