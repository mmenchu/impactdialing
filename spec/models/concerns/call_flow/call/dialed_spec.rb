require 'rails_helper'

describe 'CallFlow::Call::Dialed' do
  let(:caller_session) do
    create(:webui_caller_session, {
      campaign: campaign,
      sid: 'CA-caller-session-sid',
      on_call: true,
      available_for_call: false
    })
  end
  let(:twilio_params) do
    HashWithIndifferentAccess.new({
      'CallStatus'    => 'in-progress',
      'CallSid'       => 'CA123',
      'AccountSid'    => 'AC432',
      'campaign_id'   => campaign.id,
      'campaign_type' => campaign.type
    })
  end

  describe '#completed' do
    let(:campaign){ create(:predictive) }
    let(:status_callback_params) do
      twilio_params.merge(HashWithIndifferentAccess.new({
        'CallDuration'      => 120,
        'RecordingUrl'      => 'http://recordings.twilio.com/yep.mp3',
        'RecordingSid'      => 'RE-341',
        'RecordingDuration' => 119
      }))
    end

    subject{ CallFlow::Call::Dialed.new(status_callback_params[:AccountSid], status_callback_params[:CallSid]) }

    before do
      subject.caller_session_sid = caller_session.sid
      status_callback_params['CallStatus'] = 'completed'
    end

    it 'queues CallerPusherJob for call_ended' do
      subject.completed(campaign, status_callback_params)
      expect([:sidekiq, :call_flow]).to have_queued(CallerPusherJob).with(caller_session.id, 'call_ended')
    end

    it 'updates storage with twilio params' do
      subject.completed(campaign, status_callback_params)
      status_callback_params.each do |key,value|
        key = key.underscore.gsub('call_','')
        expect(subject.storage[key]).to eq value.to_s
      end
    end

    context '#answered never processed this call' do
      it 'tells campaign :number_not_ringing' do
        expect(campaign).to receive(:number_not_ringing)
        subject.completed(campaign, status_callback_params)
      end

      context 'dial mode is Preview' do
        let(:campaign){ create(:preview) }
        it 'redirects the caller to the next call' do
          subject.completed(campaign, status_callback_params)
          expect([:sidekiq, :call_flow]).to have_queued(RedirectCallerJob).with(caller_session.id)
        end
      end

      context 'dial mode is Power' do
        let(:campaign){ create(:power) }
        it 'redirects the caller to the next call' do
          subject.completed(campaign, status_callback_params)
          expect([:sidekiq, :call_flow]).to have_queued(RedirectCallerJob).with(caller_session.id)
        end
      end

      context 'dial mode is Predictive' do
        it 'does not redirect the caller' do
          subject.completed(campaign, status_callback_params)
          expect([:sidekiq, :call_flow]).to_not have_queued(RedirectCallerJob)
        end
      end
    end
  end

  describe '#disconnected(caller_session, params)' do
    let(:campaign){ create(:predictive) }
    let(:disconnected_params) do
      twilio_params.merge({
        RecordingUrl: 'http://recordings.twilio.com/yep.mp3',
        RecordingSid: 'RE-321'
      })
    end
    subject{ CallFlow::Call::Dialed.new(twilio_params[:AccountSid], twilio_params[:CallSid]) }

    before do
      subject.caller_session_sid = caller_session.sid
      subject.disconnected(disconnected_params)
    end

    it 'queues CallerPusherJob for voter_disconnected' do
      expect([:sidekiq, :call_flow]).to have_queued(CallerPusherJob).with(caller_session.id, 'publish_voter_disconnected')
    end

    it 'updates storage with twilio params' do
      disconnected_params.each do |key,value|
        key = key.underscore.gsub('call_','')
        expect(subject.storage[key]).to eq value.to_s
      end
    end
  end

  describe '#answered(campaign, twilio_params)' do
    let(:rest_response) do
      HashWithIndifferentAccess.new({
        'status'      => 'queued',
        'sid'         => 'CA123',
        'account_sid' => 'AC432'
      })
    end
    let(:twilio_callback_params) do
      {
        host: Settings.twilio_callback_host,
        port: Settings.twilio_callback_port,
        protocol: 'http://'
      }
    end

    subject{ CallFlow::Call::Dialed.create(campaign, rest_response, {caller_session_sid: caller_session.sid}) }

    shared_context 'answering machine setup' do
      let(:machine_twilio_params){ twilio_params.merge('AnsweredBy' => 'machine') }

      before do
        recording = create(:recording)
        campaign.update_attributes!(recording_id: recording.id)
        expect(campaign.reload.recording).to eq recording
        subject.answered(campaign, machine_twilio_params)
      end
    end

    shared_examples_for 'answered call of any dialing mode' do
      it 'updates state history to record that :answered was visited' do
        subject.answered(campaign, twilio_params)
        expect(subject.state_visited?(:answered)).to be_truthy
      end

      it 'tells campaign :number_not_ringing' do
        expect(campaign).to receive(:number_not_ringing)
        subject.answered(campaign, twilio_params)
      end

      it 'updates storage with twilio params' do
        subject.answered(campaign, twilio_params)

        expect(subject.storage['campaign_id'].to_i).to eq campaign.id
        expect(subject.storage['campaign_type']).to eq campaign.type
        expect(subject.storage['status']).to eq twilio_params['CallStatus']
      end

      context 'when call is answered by human and CallStatus == "in-progress"' do
        context 'when caller is still connected' do
          before do
            campaign.account.update_attributes(record_calls: true)
            subject.answered(campaign, twilio_params)
          end

          it 'updates RedisStatus for caller session to On call' do
            status, time = RedisStatus.state_time(campaign.id, caller_session.id)
            expect(status).to eq 'On call'
          end
          it 'queues VoterConnectedPusherJob' do
            expect([:sidekiq, :call_flow]).to have_queued(VoterConnectedPusherJob).with(caller_session.id, twilio_params['CallSid'])
          end
          it 'sets @record_calls = campaign.account.record_calls' do
            expect(subject.record_calls).to eq 'true'
          end
          it 'sets @twiml_flag = :connect' do
            expect(subject.twiml_flag).to eq :connect
          end
        end
        context 'caller has disconnected' do
          before do
            caller_session.update_attributes!({on_call: false, available_for_call: false})
          end
          it 'sets @twiml_flag = :hangup' do
            subject.answered(campaign, twilio_params)
            expect(subject.twiml_flag).to eq :hangup
          end
        end
      end

      context 'when call is answered by machine' do
        include_context 'answering machine setup'
        context 'when campaign drops message on machine' do
          let(:answering_machine_agent){ double('AnsweringMachineAgent', {leave_message?: true, record_message_drop: nil}) }

          before do
            allow(AnsweringMachineAgent).to receive(:new){ answering_machine_agent }
          end

          context 'and this is first message drop' do
            it 'records that a message was left for this phone' do
              expect(answering_machine_agent).to receive(:record_message_drop)
              subject.answered(campaign, machine_twilio_params)
            end
            it 'sets @twiml_flag = :leave_message' do
              subject.answered(campaign, machine_twilio_params)
              expect(subject.twiml_flag).to eq :leave_message
            end
          end
          context 'and this is not first dial for phone' do
            before do
              allow(answering_machine_agent).to receive(:leave_message?){ false }
            end
            it 'sets @twiml_flag = :hangup' do
              subject.answered(campaign, machine_twilio_params)
              expect(subject.twiml_flag).to eq :hangup
            end
          end
        end
      end
    end

    shared_examples_for 'Preview or Power dial modes' do
      context 'when answered by machine' do
        include_context 'answering machine setup'
        it 'redirects the caller, moving them on to next dial' do
          expect([:sidekiq, :call_flow]).to have_queued(RedirectCallerJob).with(caller_session.id)
        end
      end
    end

    context 'Preview dial mode' do
      let(:campaign){ create(:preview) }

      it_behaves_like 'answered call of any dialing mode'
      it_behaves_like 'Preview or Power dial modes'
    end

    context 'Power dial mode' do
      let(:campaign){ create(:power) }
      
      it_behaves_like 'answered call of any dialing mode'
      it_behaves_like 'Preview or Power dial modes'
    end

    context 'Predictive dial mode' do
      let(:campaign){ create(:predictive) }

      before do
        RedisOnHoldCaller.add(campaign.id, caller_session.id)
      end

      it_behaves_like 'answered call of any dialing mode'
    end
  end

  describe '.create(campaign, rest_response)' do
    subject{ CallFlow::Call::Dialed }

    let(:rest_response) do
      {
        'account_sid' => 'AC-123',
        'sid' => 'CA-3212',
        'status' => 'queued',
        'to' => '1234568890',
        'from' => '8890654321'
      }
    end
    let(:dialed_call){ subject.new(rest_response['account_sid'], rest_response['sid']) }

    context 'campaign is new or is not Preview, Power or Predictive' do
      let(:not_campaign) do
        Campaign.new
      end

      it 'raises ArgumentError' do
        expect{
          subject.create(not_campaign, rest_response)
        }.to raise_error(ArgumentError, "CallFlow::Call::Dialed received new or unknown campaign: #{not_campaign.class}")
      end
    end

    context 'campaign is Preview or Power' do
      let(:campaign){ create(:preview) }
      let(:inflight_stats){ Twillio::InflightStats.new(campaign) }
      let(:optional_properties) do
        {
          'caller_session_sid' => 'CA-cs123'
        }
      end

      before do
        expect(inflight_stats.get('presented')).to be_zero
        subject.create(campaign, rest_response, optional_properties)
      end

      it 'increments "ringing" count for campaign by 1' do
        expect(inflight_stats.get('ringing')).to eq 1
      end
      it 'does not decrement "presented" count for campaign' do
        expect(inflight_stats.get('presented')).to be_zero
      end
      it 'saves rest_response to attached storage instance' do
        rest_response.each do |property,value|
          expect(dialed_call.storage[property]).to eq value
        end
      end
      it 'saves caller_session_id to attached storage instance' do
        expect(dialed_call.caller_session_sid).to eq optional_properties['caller_session_sid']
      end
    end

    context 'campaign is Predictive' do
      let(:campaign){ create(:predictive) }
      let(:inflight_stats){ Twillio::InflightStats.new(campaign) }

      before do
        inflight_stats.incby 'presented', 1
        subject.create(campaign, rest_response, {})
      end

      it 'increments "ringing" count for campaign by 1' do
        expect(inflight_stats.get('ringing')).to eq 1
      end
      it 'decrements "presented" count for campaign by 1' do
        expect(inflight_stats.get('presented')).to eq 0
      end
      it 'saves rest_response' do
        rest_response.each do |property,value|
          expect(dialed_call.storage[property]).to eq value
        end
      end
    end
  end
end
