//
//  StageViewRenderer.swift
//  Runner
//
//  Created by Yogesh Markandey on 25/05/25.
//

import Foundation
import AmazonIVSBroadcast

class StageViewRenderer : NSObject {
    private let getParticipantsData: () -> [ParticipantData]
       private let setParticipantsData: ([ParticipantData]) -> Void
       private let signalParticipantUpdate: (_ index: Int, _ changeType: ChangeType) -> Void
       private let mutatingParticipant: (_ participantId: String?, _ mutation: (inout ParticipantData) -> Void) -> Void
       private let displayErrorAlert: (_ error: Error,_ logSource: String?) -> Void
       private let stageConnectionStateUpdate: ((IVSStageConnectionState) -> Void)?

       init(
           getParticipantsData: @escaping () -> [ParticipantData],
           setParticipantsData: @escaping ([ParticipantData]) -> Void,
           signalParticipantUpdate: @escaping (_ index: Int, _ changeType: ChangeType) -> Void,
           mutatingParticipant: @escaping (_ participantId: String?, _ mutation: (inout ParticipantData) -> Void) -> Void,
           displayErrorAlert: @escaping (_ error: Error,_ logSource: String?) -> Void,
           stageConnectionStateUpdate: ((IVSStageConnectionState) -> Void)? = nil
       ) {
           self.getParticipantsData = getParticipantsData
           self.setParticipantsData = setParticipantsData
           self.signalParticipantUpdate = signalParticipantUpdate
           self.mutatingParticipant = mutatingParticipant
           self.displayErrorAlert = displayErrorAlert
           self.stageConnectionStateUpdate = stageConnectionStateUpdate
       }
}

extension StageViewRenderer : IVSStageRenderer {
    // MARK: - IVSStageRenderer Methods
    func stage(_ stage: IVSStage, participantDidJoin participant: IVSParticipantInfo) {
        print("[IVSStageRenderer] participantDidJoin - \(participant.participantId)")
        var data = getParticipantsData()

        if participant.isLocal {
            data[0].participantId = participant.participantId
            setParticipantsData(data)
            signalParticipantUpdate(0, .updated)
        } else {
            data.append(ParticipantData(isLocal: false, participantId: participant.participantId))
            setParticipantsData(data)
            signalParticipantUpdate(data.count - 1, .inserted)
        }
    }

    func stage(_ stage: IVSStage, participantDidLeave participant: IVSParticipantInfo) {
        print("[IVSStageRenderer] participantDidLeave - \(participant.participantId)")
        var data = getParticipantsData()

        if participant.isLocal {
            data[0].participantId = nil
            setParticipantsData(data)
            signalParticipantUpdate(0, .updated)
        } else if let index = data.firstIndex(where: { $0.participantId == participant.participantId }) {
            data.remove(at: index)
            setParticipantsData(data)
            signalParticipantUpdate(index, .deleted)
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange publishState: IVSParticipantPublishState) {
        print("[IVSStageRenderer] participant \(participant.participantId) didChangePublishState to \(publishState.text)")
        mutatingParticipant(participant.participantId) { data in
            data.publishState = publishState
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange subscribeState: IVSParticipantSubscribeState) {
        print("[IVSStageRenderer] participant \(participant.participantId) didChangeSubscribeState to \(subscribeState.text)")
        mutatingParticipant(participant.participantId) { data in
            data.subscribeState = subscribeState
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didAdd streams: [IVSStageStream]) {
        print("[IVSStageRenderer] participant (\(participant.participantId)) didAdd \(streams.count) streams")
        guard !participant.isLocal else { return }

        mutatingParticipant(participant.participantId) { data in
            data.streams.append(contentsOf: streams)
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didRemove streams: [IVSStageStream]) {
        print("[IVSStageRenderer] participant (\(participant.participantId)) didRemove \(streams.count) streams")
        guard !participant.isLocal else { return }

        mutatingParticipant(participant.participantId) { data in
            let removedUrns = streams.map { $0.device.descriptor().urn }
            data.streams.removeAll { stream in
                removedUrns.contains(stream.device.descriptor().urn)
            }
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChangeMutedStreams streams: [IVSStageStream]) {
        print("[IVSStageRenderer] participant (\(participant.participantId)) didChangeMutedStreams")
        let data = getParticipantsData()
        guard !participant.isLocal else { return }

        if let index = data.firstIndex(where: { $0.participantId == participant.participantId }) {
            signalParticipantUpdate(index, .updated)
        }
    }

    func stage(_ stage: IVSStage, didChange connectionState: IVSStageConnectionState, withError error: Error?) {
        print("[IVSStageRenderer] didChangeConnectionStateWithError to \(connectionState.text)")
        stageConnectionStateUpdate?(connectionState)
        if let error = error {
            displayErrorAlert(error, nil)
        }
    }
}
