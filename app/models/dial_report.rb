class DialReport
  
  def compute_campaign_report(campaign, from_date, to_date)
    @from_date = from_date
    @to_date = to_date
    @campaign = campaign
    @leads_not_dialed = @campaign.all_voters.enabled.by_status(Voter::Status::NOTCALLED).count    
    @lead_dials = @campaign.all_voters.last_call_attempt_within(@from_date, @to_date).group("status").count
    @scheduled_for_now =  @campaign.all_voters.scheduled.count
  end
  
  
  def per_attempt_dials
    @total_attempts_count = @campaign.call_attempts.between(@from_date, @to_date).count
    @per_attempt_dials = @campaign.call_attempts.between(@from_date, @to_date).group("status").count
    @total_attempt_dials = ((@total_attempts_count == 0) ? 1 : @total_attempts_count)
    @ready_to_dial_attempts = params[:from_date] ? 0 : sanitize_dials(@per_attempt_dials[CallAttempt::Status::READY])
    @total_dials_made_attempts = total_dials(@per_attempt_dials)
  end
  
   def per_lead_dials      
      @total_voters_count = @campaign.all_voters.last_call_attempt_within(@from_date, @to_date).count         
      @total_lead_dials = ((@total_voters_count == 0) ? 1 : @total_voters_count)
      @total_dials_made_leads = total_dials(@lead_dials)
    end
  
  def leads_available_for_retry
    @leads_available_retry = @campaign.all_voters.enabled.avialable_to_be_retried(recycle_rate).count + scheduled_for_now + 
    @campaign.all_voters.by_status(CallAttempt::Status::ABANDONED).count    
  end
  
  def scheduled_for_now
    @scheduled_for_now
  end
  
  def dialed_and_completed
    @dialed_and_completed = sanitize_dials(@lead_dials[CallAttempt::Status::SUCCESS]) + sanitize_dials(@lead_dials[CallAttempt::Status::FAILED])
  end
  
  def leads_not_available_for_retry
    @leads_not_available_for_retry = (@campaign.all_voters.by_status(CallAttempt::Status::SCHEDULED).count - scheduled_for_now) + @campaign.all_voters.enabled.not_avialable_to_be_retried(recycle_rate).count
  end
  
  def overview_summary
     @total_summary = @dialed_and_completed + @leads_not_dialed + @leads_not_available_for_retry + @leads_available_retry  
  end
  
  def sanitize_dials(dial_count)
    dial_count.nil? ? 0 : dial_count
  end
  
  
   
end
