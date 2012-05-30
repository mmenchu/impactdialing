class CampaignReportStrategy
  
  module Mode
    PER_LEAD = "lead"
    PER_DIAL = "dial"
  end
  
  module AttemptStatus
    ANSWERED = "Answered"
    ABANDONED = "Abandoned"
    FAILED = "Failed"
    BUSY = "Busy"
    NOANSWER = 'No answer'
    ANSWERING_MACHINE = "Answering machine"
    ANSWERING_MACHINE_MESSAGE = "Answering machine message delivered"
    SCHEDULED = 'Scheduled for later'
    NOT_DIALED = "Not Dialed"
  end
  
  def self.map_status(status)
    statuses = {CallAttempt::Status::SUCCESS => AttemptStatus::ANSWERED, Voter::Status::RETRY => AttemptStatus::ANSWERED, 
      Voter::Status::NOTCALLED => AttemptStatus::NOT_DIALED, CallAttempt::Status::NOANSWER => AttemptStatus::NOANSWER, 
      CallAttempt::Status::ABANDONED => AttemptStatus::ABANDONED, CallAttempt::Status::BUSY => AttemptStatus::BUSY,
      CallAttempt::Status::FAILED => AttemptStatus::FAILED, CallAttempt::Status::HANGUP => AttemptStatus::ANSWERING_MACHINE,
      CallAttempt::Status::SCHEDULED => AttemptStatus::SCHEDULED, CallAttempt::Status::VOICEMAIL => AttemptStatus::ANSWERING_MACHINE_MESSAGE}
      statuses[status] || status
  end
  
  
  def initialize(campaign, csv, download_all_voters, mode, selected_voter_fields, selected_custom_voter_fields)
    @campaign = campaign
    @download_all_voters = download_all_voters ? ("download_all_voters_" + mode) : ("download_for_date_range_" + mode)
    @mode = mode
    @csv = csv
    @selected_voter_fields = selected_voter_fields
    @selected_custom_voter_fields = selected_custom_voter_fields
    @question_ids = Answer.question_ids(@campaign.id)
    @note_ids = NoteResponse.note_ids(@campaign.id)           
  end
  
  def construct_csv
    @csv << csv_header    
  end
  
  def csv_for(voter)
     voter_fields = voter.selected_fields(@selected_voter_fields.try(:compact))
     custom_fields = voter.selected_custom_fields(@selected_custom_voter_fields)
     [voter_fields, custom_fields, call_details(voter, @question_ids, @note_ids)].flatten
  end
  
  def csv_for_call_attempt(call_attempt)
    voter = call_attempt.voter
    voter_fields = voter.selected_fields(@selected_voter_fields.try(:compact))
    custom_fields = voter.selected_custom_fields(@selected_custom_voter_fields)
    [voter_fields, custom_fields, call_attempt_details(call_attempt, voter, @question_ids, @note_ids)].flatten
  end
  
  def call_attempt_info(call_attempt)
    if @mode == CampaignReportStrategy::Mode::PER_LEAD
      [caller_name(call_attempt), CampaignReportStrategy.map_status(call_attempt.status), call_start_time(call_attempt),
       call_end_time(call_attempt),number_of_attempts(call_attempt.voter), call_attempt.try(:report_recording_url)].flatten
    else
      [caller_name(call_attempt), CampaignReportStrategy.map_status(call_attempt.status), call_start_time(call_attempt),
       call_end_time(call_attempt), call_attempt.try(:report_recording_url)].flatten      
    end
     
  end
  
  def caller_name(call_attempt)
    call_attempt.try(:caller).try(:known_as)
  end
  
  def call_start_time(call_attempt)
    call_attempt.try(:call_start).try(:in_time_zone, @campaign.time_zone)
  end
  
  def number_of_attempts(voter)
    voter.call_attempts.size
  end
  
  def call_end_time(call_attempt)
    call_attempt.try(:call_end).try(:in_time_zone, @campaign.time_zone)
  end
  
  def answers(call_attempt)
    call_attempt.answers.for_questions(@question_ids).order('question_id')
  end
  
  def note_responses(call_attempt)
    call_attempt.note_responses.for_notes(@note_ids).order('note_id')
  end
  
end