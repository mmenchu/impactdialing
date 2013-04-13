ImpactDialing.Views.CampaignCall = Backbone.View.extend({

  initialize: function(){
    this.caller_script = new ImpactDialing.Models.CallerScript();
    this.script_view  = new ImpactDialing.Views.CallerScript({model: this.caller_script});
    this.start_calling_view = new ImpactDialing.Views.StartCalling({model: this.model});
    this.caller_actions = new ImpactDialing.Views.CallerActions({model: this.model});
    this.caller_session = new ImpactDialing.Models.CallerSession();
    this.lead_info = new ImpactDialing.Models.LeadInfo();
    this.fetchCallerInfo();
  },


  render: function(){
    var self = this;
    this.caller_script.fetch({success: function(){
      $("#voter_responses").html(self.script_view.render().el);
    }});

  },

  fetchCallerInfo: function(){
    var self = this;
    $.ajax({
      type: 'POST',
      url: "/callers/campaign_calls/token",
      dataType: "json",
      beforeSend: function(request)
        {
          var token = $("meta[name='csrf-token']").attr("content");
          request.setRequestHeader("X-CSRF-Token", token);
        },
      success: function(data){
        console.log(data)
        self.model.set(data);
        self.pusher = new Pusher(self.model.get("pusher_key"))
        self.channel = self.pusher.subscribe(self.model.get("session_key"));
        self.bindPusherEvents();

        $("#caller-actions").html(self.start_calling_view.render().el);
        $("#callin").show();
        $("#callin-number").html(self.model.get("phone_number"));
        $("#callin-pin").html(self.model.get("pin"));
        self.setupTwilio();
        },
      error: function(jqXHR, textStatus, errorThrown){
        self.callerShouldNotDial(jqXHR["responseText"]);
      },
      });
  },

  callerShouldNotDial:  function(error){
    $("#caller-alert p strong").html(error);
    $("#caller-alert").addClass("callout alert clearfix")
  },

   setupTwilio:  function(){
    var self = this;
    Twilio.Device.setup(this.model.get("twilio_token"), {'debug':true});
    Twilio.Device.connect(function (conn) {
        $("#start_calling").hide();
        $("#caller-actions").html(self.caller_actions.render().el);
        $("#caller-actions a").hide();
    });
    Twilio.Device.ready(function (device) {
      client_ready=true;
    });
    Twilio.Device.error(function (error) {
      alert(error.message);
    });
  },

  bindPusherEvents: function(){
    var self = this;
    this.channel.bind('start_calling', function(data) {
      self.model.set("session_id", data.caller_session_id)
      self.caller_actions.startCalling();
    });

    this.channel.bind('conference_started', function(data) {
      self.lead_info.set(data)
      var lead_info_view = new ImpactDialing.Views.LeadInfo({model: self.lead_info})
      $("#voter_info_message").empty();
      $("#voter_info").html(lead_info_view.render().el);
      self.caller_actions.conferenceStarted(self.lead_info);
    });

    this.channel.bind('calling_voter', function(data) {
      self.caller_actions.callingVoter();
    });

    this.channel.bind('voter_connected', function(data) {
      self.model.set("call_id", data.call_id);

    });

    this.channel.bind('voter_connected_dialer', function(data) {
    });

    this.channel.bind('voter_disconnected', function(data) {
    });

    this.channel.bind('caller_disconnected', function(data) {
        var campaign_call = new ImpactDialing.Models.CampaignCall();
        campaign_call.set({pusher_key: data.pusher_key});
        var campaign_call_view = new ImpactDialing.Views.CampaignCall({model: campaign_call});
        campaign_call_view.render();
    });

  },



});