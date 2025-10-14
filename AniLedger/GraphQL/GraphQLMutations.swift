//
//  GraphQLMutations.swift
//  AniLedger
//
//  Created by Kiro on 10/13/2025.
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
