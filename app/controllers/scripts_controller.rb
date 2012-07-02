class ScriptsController < ClientController
  layout 'v2'
  include DeletableController
  before_filter :full_access
  before_filter :new_script, :only => [:new, :create]
  before_filter :load_script, :only => [:update, :show, :destroy, :edit]
  before_filter :apply_changes, :only => [:create, :update]
  


  def type_name
    'script'
  end

  def load_script
    @script = Script.find(params[:id])
  end

  def index
  @scripts = @user.account.scripts.active.robo.paginate(:page => params[:page])
  end
  
  def load_deleted
    self.instance_variable_set("@#{type_name.pluralize}", @user.account.scripts.deleted.robo.for_account(@user.account).paginate(:page => params[:page], :order => 'id desc'))
  end    
  
  
  def deleted
    render 'scripts/deleted'
  end
  
  
  def new_script
    @fields = ["CustomID", "FirstName", "MiddleName", "LastName", "Suffix", "Age", "Gender", "Phone", "Email"]
    @breadcrumb=[{"Scripts"=>"/client/scripts"}, "Add Script"]
    @label = 'New Script'
    @script = @user.account.scripts.new(:name => 'Untitled Script', :robo=>true)
    @voter_fields = []
  end

  def new
    @script.robo_recordings.build
  end

  def create
    #before filter apply_changes triggered here
  end

  def update
    #before filter apply_changes triggered here
  end

  def apply_changes
    @script.update_attributes(params[:script])
    if @script.valid?
      @script.voter_fields = params[:voter_field] ? params[:voter_field].to_json : nil
      @script.save
      flash_message(:notice, "Script saved")
      redirect_to scripts_path
    else
      render :action => 'new'
    end
  end

  def show
    @fields = ["CustomID", "FirstName", "MiddleName", "LastName", "Suffix", "Age", "Gender", "Phone", "Email"]
    @breadcrumb=[{"Scripts"=>"/client/scripts"}, "Edit Script"]
    @label = "Add script"
    render :template => 'scripts/new'
  end
  
end
