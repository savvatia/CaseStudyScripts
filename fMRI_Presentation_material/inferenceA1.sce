##############################################################################
##                                                                          ##
##              Experiment Script for use with Presentation                 ##
##                     Written by Salomi S. Asaridou                        ##
##                   Adapted from Script by Sarah Tune                      ##
##                                                                          ##
##############################################################################

##############################################################################
# Scenario Description Language (SDL) Header Part
##############################################################################

#scenario_type = fMRI_emulation;		            # in order to test the experiment uncomment emulation
scenario_type = fMRI; 
scan_period = 2000; 				                  # only for emulation the scan period must be specified
pulses_per_scan = 1;   			
pulse_code = 66;	                              # define in settings -> port, fMRI mode triggers, value: 66				

# These button codes have to correspond to those set in 'Settings -> Response' 
active_buttons = 3;                             # There are 3active buttons defined in 'Settings -> Response'
button_codes = 1,2,3;                           # These are the codes of those buttons
response_matching = simple_matching;            # Enables features not in legacy_matching

# Only those button presses that one expects are logged; not all
response_logging = log_active;                


# Default Settings for Font, FG and BG Colours etc.
default_background_color = "90,90,90";        # RGB codes in decimal; '51,51,255' => Blue; '0,0,0' => Black
default_font = "Arial";
default_font_size = 40;
default_text_color = "0,0,0";                 # Black
default_text_align = align_center;            # Elements centered on screen

default_deltat = 0;
default_picture_duration = next_picture; /* This implies that all pictures ...
/...are shown until the next picture is shown, unless otherwise specified */

##############################################################################
# Scenario Description Language (SDL) Part
##############################################################################

begin;

# ============================
# SDL Variable Declarations: -
# ============================

# We don't use any variables.  All the timer parameters appear as numbers.

# ==============================
# Picture Stimuli Definitions: - Everything that is shown, including text!
# ==============================

# Screen definition for the trial that starts an Experimental Session.
# Used as the first screen that the participant sees.  

picture 
{   
	text 
	{
		caption = "Welcome!\nPart 1 of this experiment is about to start.";
	};
	x = 0;
	y = 0;
} P_Start_Exp;



# Default Screen definition
picture { } P_Default;


# Screen definition for showing the focus star
picture
{
	text 
	{ 
		caption = "+";
		font_size = 70;
	}Txt_Focus_Star;
	x = 0;
	y = 0;
} P_Focus_Star;

# Screen definition for showing the question mark
picture 
{    
	text 
	{ 
		caption = "?"; 
		font_size = 70;
	};
	x = 0;
	y = 0;
} P_Show_Question_Mark;

# \u263a unicode smiley
# \u2639 unicode frowny


picture 
{    
	text 
	{ 
		 caption = "TRUE             FALSE"; 
		 font_size = 60;
		 #caption = "\n\n?\n\n\n\u263a                          \u2639";
	};
	x = 0;
	y = 0;
} P_Answer;



# Screen definition for the End_Thanks trial
picture 
{ 
	text 
	{
		caption = "End of part 1.\n\n\u263a";
		font_size = 70;
	};
	x = 0;
	y = 0;
} P_End_Thanks;


# ============================
# Sound Stimuli Definitions: - 
# ============================

sound
{
	wavefile 
	{ 
		filename = "";        # PCL Program below fills the file name  
		preload = false;
	} Wav_Sentence;
} S_Sentence;


#=====================
# Trial Definitions: -
#=====================



# Definition of the Catch Trial to show ??? for True/False Judgement.
trial
{
	trial_duration = forever;
	trial_type = specific_response;
	terminator_button = 1,2;  # The exact response can be either of these;
	stimulus_event
	{
		picture P_Answer; 
		code = "25";                    
	} E_Show_Answer;              	
} T_Show_Answer; 



# Definition of the Trial to start an Experimental Session.

trial 
{ 
    all_responses = false;
    trial_duration = 6000;
	stimulus_event 
	{
		picture P_Start_Exp; 
		code = "20";                 	# Show P_Start_Exp.
	} E_Start_Exp;
} T_Start_Exp;




# Definition of the Trial to Launch an Experimental Trial (ITI: jitter)

trial
{
#	trial_duration = 500;       # will define the ITI duration in PCL  
	all_responses = false;      # ..without recognising any key presses.
	stimulus_event
	{
		picture P_Default;  		 # Show the focus star for fixation.
	} E_star_ITI;
} T_star_ITI;


# Definition of the Trial to play the Sentence
trial
{
	trial_duration = stimuli_length;
	all_responses = false;
	picture P_Focus_Star;
	stimulus_event
	{
		sound S_Sentence;
#		code = "140";                        # PCL Program sets Event code
	} E_Sentence;
} T_Sentence;


# Definition of the Catch Trial
trial
{
	trial_duration = stimuli_length;
	all_responses = false;
	picture P_Show_Question_Mark;
	stimulus_event
	{
		sound S_Sentence;
#		code = "140";                        # PCL Program sets Event code
	} E_Catch;
} T_Catch;

#the ISI between context-target with a fixation asterisk, duration to be defined in PCL
trial
{
    all_responses = false;
    stimulus_event
    {
        picture P_Focus_Star;     
    } E_star_ISI;
} T_star_ISI;


# Definition of the Trial to end the runs
# Operator Controlled

trial
{
	trial_duration = forever;
	all_responses = false;
	trial_type = first_response;
	stimulus_event
	{
		picture P_End_Thanks;
		code = "29";
	};
} T_End_Thanks;


##############################################################################
# Presentation Control Language (PCL) Program Part
##############################################################################

begin_pcl;


int N_of_Trials = 43;                               # Number of Experimental Trials per run.  
int N_of_Blocks = 1;                                 # Number of Blocks per run.                       
int N_of_Trials_per_Block = N_of_Trials/N_of_Blocks; # Number of Experimental Trials per Block.



# Columns of strings in the order found in the input Session List file.
# Number of items in each column is number of experimental trials per session i.e. N_of_Trials
array<string> Col_1[N_of_Trials]; # Trial type (context, target, catch, response)
array<string> Col_2[N_of_Trials]; # ItemNo
array<string> Col_3[N_of_Trials]; # Condition
array<string> Col_4[N_of_Trials]; # Wavefile  
array<string> Col_5[N_of_Trials]; # Expected Response

# This is the file containing the list of stimuli for one session.
# Each line in this file must correspond to one experimental trial.
input_file F_Session_List = new input_file;
F_Session_List.open("rlistA1.txt");

loop # Begin loop		
	int i = 1
until
	i > Col_1.count()
begin
	Col_1[i] = F_Session_List.get_string();
	Col_2[i] = F_Session_List.get_string();
  	Col_3[i] = F_Session_List.get_string();
	Col_4[i] = F_Session_List.get_string();
	#Col_5[i] = F_Session_List.get_string();
	i = i + 1
end;

# Close the open file
F_Session_List.close(); 

# Variables for stimulus codes etc.
string V_Type;
string V_Item;
string V_Condition;
string V_Wavefile;
#string V_Expected_Response;
 

int ITI;
int ISI;

stimulus_data D_Stimulus_Data = stimulus_manager.last_stimulus_data();
int D_Last_Response = response_manager.last_response();

int V_Item_Counter = 1;		# Counts all trials in experiment
int start_pulse;

string debug_help;


#========================
# Main Experiment Loop: -
#========================

loop     # Begin Main Loop 1 for Blocks
    int V_Current_Block = 1

until  
    V_Current_Block > N_of_Blocks

begin

	if	V_Current_Block == 1  then
		T_Start_Exp.set_mri_pulse(pulse_manager.main_pulse_count()+1);
		T_Start_Exp.present();   #First Introduction Screen is presented for 8s#
		
		start_pulse = pulse_manager.main_pulse_count()+1;

	end;

	#==================
	# Loop 2: - Trials
	#==================

	loop   
		 int V_Trial_in_Block = 1

	until
		 V_Trial_in_Block > N_of_Trials_per_Block


	begin

			 V_Type = Col_1[V_Item_Counter];
			 V_Item = Col_2[V_Item_Counter];
			 V_Condition = Col_3[V_Item_Counter];
			 V_Wavefile = Col_4[V_Item_Counter];

			
			
		if (V_Type == "con") then # Conext sentence presentation
			
				 Wav_Sentence.set_filename(V_Wavefile);   # Why Wav_Sentence and not S_Sentence?
				 Wav_Sentence.load();
				 
				 E_Sentence.set_event_code("21"); 
				 T_Sentence.set_duration(stimuli_length);  ##### !!!! Duration? ######
				 T_Sentence.present();

				 Wav_Sentence.unload();

				# ISI interval

				 ISI = random(2000,4000);
				 T_star_ISI.set_duration(ISI); 
				 E_star_ISI.set_event_code("27");   
				 T_star_ISI.present();

		
		elseif (V_Type == "targ") then # Target sentence presentation		
		 
				 Wav_Sentence.set_filename(V_Wavefile);
				 Wav_Sentence.load();

				 if (V_Condition == "surprising") then E_Sentence.set_event_code("22");  
				 elseif (V_Condition == "unsurprising") then E_Sentence.set_event_code("23"); end;
       
				 T_Sentence.set_duration(stimuli_length);  
				 T_Sentence.present();

				 Wav_Sentence.unload();

				# ITI interval

				 ITI = random(6000,12000);
				 T_star_ITI.set_duration(ITI); 
				 E_star_ITI.set_event_code("26");   # 6= ITI Jittered
				 T_star_ITI.present();
				
		
		elseif (V_Type == "catch") then # Catch trial presentation
				

				 Wav_Sentence.set_filename(V_Wavefile);
				 Wav_Sentence.load();
				 E_Catch.set_event_code("24");
				 T_Catch.set_duration(stimuli_length);   
				 T_Catch.present();

				 Wav_Sentence.unload();		 
		
				 E_Show_Answer.set_event_code("25");
        		 #T_Show_Answer.set_duration(forever);        
        		 T_Show_Answer.present();  


				D_Stimulus_Data = stimulus_manager.last_stimulus_data();
				D_Last_Response = 0;


				# ITI interval

				 ITI = random(6000,12000);
				 T_star_ITI.set_duration(ITI); 
				 E_star_ITI.set_event_code("28");   
				 T_star_ITI.present();
		
		
		end;
		

	#end; #closes the if block for sentence type (context, target, response). 
			 
	V_Trial_in_Block = V_Trial_in_Block + 1;
	V_Item_Counter = V_Item_Counter + 1;

   #===========
   # End Loop 2 
   #===========

end; /*** End Trials loop ***/

# Go to the Next Block
V_Current_Block = V_Current_Block + 1;

#================
# End Main Loop 1 
#================
end;    /*** End Blocks  loop***/

# Finish off the session!!!
T_End_Thanks.present();