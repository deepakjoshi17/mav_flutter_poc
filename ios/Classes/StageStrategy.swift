//
//  StageStrategy.swift
//  Runner
//
//  Created by Yogesh Markandey on 25/05/25.
//

import Foundation
import AmazonIVSBroadcast

class StageStrategy: NSObject {
    
    private let dataForParticipant: (String) -> ParticipantData?
    private let getLocalUserWantsPublish: () -> Bool
    private let getLocalStreams: () -> [IVSLocalStageStream]
    private let getScreenShareStream: () -> IVSLocalStageStream?
    private let getScreenShareParticipantId: () -> String?
    
    init(
        dataForParticipant: @escaping (String) -> ParticipantData?,
        getLocalUserWantsPublish: @escaping () -> Bool,
        getLocalStreams: @escaping () -> [IVSLocalStageStream],
        getScreenShareStream: @escaping () -> IVSLocalStageStream?,
        getScreenShareParticipantId: @escaping () -> String?
    ) {
        self.dataForParticipant = dataForParticipant
        self.getLocalUserWantsPublish = getLocalUserWantsPublish
        self.getLocalStreams = getLocalStreams
        self.getScreenShareStream = getScreenShareStream
        self.getScreenShareParticipantId = getScreenShareParticipantId
    }
}

extension StageStrategy: IVSStageStrategy {
    func stage(_ stage: IVSStage, shouldSubscribeToParticipant participant: IVSParticipantInfo) -> IVSStageSubscribeType {
        guard let data = dataForParticipant(participant.participantId) else {
            return .none
        }
        return data.isAudioOnly ? .audioOnly : .audioVideo
    }

    func stage(_ stage: IVSStage, shouldPublishParticipant participant: IVSParticipantInfo) -> Bool {
        return getLocalUserWantsPublish()
    }

    func stage(_ stage: IVSStage, streamsToPublishForParticipant participant: IVSParticipantInfo) -> [IVSLocalStageStream] {
        var streams = getLocalStreams()
        
        if participant.participantId == getScreenShareParticipantId(), let screenShare = getScreenShareStream() {
            streams.append(screenShare)
        }

        return streams
    }
}

