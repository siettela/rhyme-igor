#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

//____________________________________________________________________________
//	Rhyme-Igor: Raman Hyperspectral image Management Environment for Igor Pro
//									= Add-On = 
//							Multivariate Curve Resolution Pack
//
//	Written by Ren Shibuya 
//	Github Repository: https://github.com/siettela/rhyme-igor
//	
//	2023-11-24 - ver. 1.00: Initial public release (MCR).
//____________________________________________________________________________

Menu "Rhyme"
	Submenu "Multivariate Analysis"
		"MCR",/Q, LaunchMCRPanel()
	end
End		

static strconstant RHYME_PATH = "root:RHYME"
static strconstant PARAMS_PATH = ":Params"	// Parameter of main analyze panel
static strconstant MCR_PATH = ":MCR"	// Parameter of Multivariate Curve Resolution(MCR). 

//__________________________________________________________________
// *** Make Data Folder and Global Variables, Strings and Waves ***
//__________________________________________________________________
Static Function AfterCompiledHook()	//Make Folder and Variables when this procedure is compiled.
	PrepareDataFolder()
	PrepareGlobalVars()
End

Static Function PrepareDataFolder()	//Make data folder for multivariate analysis parameters if it does not exist.
	if(!DataFolderExists(RHYME_PATH))
		NewDataFolder $RHYME_PATH
	endif

	if(!DataFolderExists(RHYME_PATH + MCR_PATH))	//Multivariate Curve Resolution(MCR)
		NewDataFolder $(RHYME_PATH + MCR_PATH)
	endif
End

Static Function PrepareGVariable(Path,gVarName, DefaultVal)	// Make and initialize a global variable if it does not exist.
	String Path
	String gVarName
	Variable DefaultVal
	NVAR gVar = $(RHYME_PATH+Path+":"+gVarName)
	if(!NVAR_Exists(gVar))
		Variable/G $(RHYME_PATH+Path+":"+gVarName) = DefaultVal
	endif
End

Static Function PrepareGString(Path,gStrName, DefaultStr)	// Make and initialize a global string if it does not exist.
	String Path
	String gStrName
	String DefaultStr
	SVAR gStr = $(RHYME_PATH+Path+":"+gStrName)
	if(!SVAR_Exists(gStr))
		String/G $(RHYME_PATH+Path+":"+gStrName) = DefaultStr
	endif
End

Static Function PrepareGWave(Path,gWaveName,DefaultRow,DefaultCol,DefaultLayer,DefaultChunk) // Make and initialize a global wave if it does not exist.
	String Path
	String gWaveName
	Variable DefaultRow,DefaultCol,DefaultLayer,DefaultChunk
	WAVE gWave = $(RHYME_PATH+Path+":"+gWaveName)
	if(!WaveExists(gWave))
		Make/N=(DefaultRow,DefaultCol,DefaultLayer,DefaultChunk) $(RHYME_PATH+path+":"+gWaveName)
	endif	
End

Static Function PrepareGlobalVars()	//Make global variables required for multivariate analysis.
	DFREF dfr_params = $(RHYME_PATH+PARAMS_PATH)
	
	//++++++++++++++++++++ MCR +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	PrepareGVariable(MCR_PATH,"G_MCRComponentsNum",5)
	PrepareGVariable(MCR_PATH,"G_MCRItrNum",200)
	PrepareGVariable(MCR_PATH,"G_MCRRecordHistNum",50)
	PrepareGVariable(MCR_PATH,"G_MCRInitMethod",5)
	PrepareGVariable(MCR_PATH,"G_MCRInitWaveType",0)
	PrepareGVariable(MCR_PATH,"G_MCROptMethod",1)
	PrepareGVariable(MCR_PATH,"G_MCRRunNum",0)
	PrepareGVariable(MCR_PATH,"G_MCRBetweenRunSec",0.1)
	PrepareGVariable(MCR_PATH,"V_running",0)
	PrepareGVariable(MCR_PATH,"V_paused",0)
	
	PrepareGString(MCR_PATH,"G_MCRTrgtWaveName","None")
	PrepareGString(MCR_PATH,"G_MCRxWaveName","None")
	PrepareGString(MCR_PATH,"G_MCRMaskWaveName","None")
	
	PrepareGString(MCR_PATH,"G_TempSMXWaveName","None")
	PrepareGString(MCR_PATH,"G_TempCMXWaveName","None")
	PrepareGString(MCR_PATH,"G_ResSMXWaveName","None")
	PrepareGString(MCR_PATH,"G_ResCMXWaveName","None")	
End

//_____________________________
// *** ====MCR====  ***
//_____________________________
//_____________________________
// *** - Launch Panel ***
//_____________________________

Function LaunchMCRPanel()

	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	NVAR G_MCROptMethod = dfr_MCR:G_MCROptMethod
	NVAR G_MCRBetweenRunSec = dfr_MCR:G_MCRBetweenRunSec
	NVAR G_MCRRecordHistNum = dfr_MCR:G_MCRRecordHistNum
	NVAR G_MCRInitWaveType = dfr_MCR:G_MCRInitWaveType
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_MCRxWaveName = dfr_MCR:G_MCRxWaveName
	SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	SVAR G_ResSMXWaveName = dfr_MCR:G_ResSMXWaveName
	SVAR G_ResCMXWaveName = dfr_MCR:G_ResCMXWaveName
	
	//Restrict window overlap
	DoWindow/F winMCRAnalyzer
	if(V_flag)
		return 0
	endif
	PauseUpdate; Silent 1		// building window...
	
	//___________
	// Host Panel
	//___________
	Newpanel /K=1 /W=(180,110,590,800) as "MCR Analyzer"
	RenameWindow $S_name, winMCRAnalyzer
	Modifypanel /W=$"winMCRAnalyzer" fixedsize=1
	SetDrawLayer UserBack
	SetDrawEnv fsize= 20,fstyle= 1
	DrawText 16,27,"MCR config"
	
	//___________________
	// Wave Select Group
	//___________________
	GroupBox MCRWvSelectGroup,pos={10,35},size={390,100}
	GroupBox MCRWvSelectGroup,title="WAVE SELECT",font="Arial",fSize=12,fStyle=1
	PopupMenu Trgt2dWList,pos={28,59},size={245,20},bodyWidth=210,disable=G_MCRInitWaveType,proc=MCRPopMenuProc
	PopupMenu Trgt2dWList,title="Wave:",font="Arial",fSize=12
	PopupMenu Trgt2dWList,mode=1,popvalue=G_MCRTrgtWaveName,value=#"Wavelist(\"*\",\";\",\"DIMS:2\")"
	PopupMenu XaxisWList,pos={28,83},size={245,20},bodyWidth=210,proc=MCRPopMenuProc
	PopupMenu XaxisWList,title="xAxis:",font="Arial",fSize=12
	PopupMenu XaxisWList,mode=1,popvalue=G_MCRxWaveName,value=#"Wavelist(\"*\",\";\",\"DIMS:1\")"
	CheckBox CheckApplyMask,pos={25,107},size={49,16},title=""
	CheckBox CheckApplyMask,font="Arial",fSize=12,value=0
	PopupMenu MaskWList,pos={78,107},size={195,20},bodyWidth=195,proc=MCRPopMenuProc
	PopupMenu MaskWList,title="Mask:",font="Arial",fSize=12
	PopupMenu MaskWList,mode=1,value=#"Wavelist(\"*\",\";\",\"DIMS:3\")"

	//__________________
	// Initialize Group
	//__________________
	GroupBox MCRInitGroup,pos={10,145},size={390,125}
	GroupBox MCRInitGroup,title="INITIALIZE",font="Arial",fSize=12,fStyle=1
	PopupMenu InitMethodList,pos={25.00,165.00},size={250.00,20.00},bodyWidth=160,proc=MCRPopMenuProc
	PopupMenu InitMethodList,title="Initialize method",font="Arial",fSize=12
	PopupMenu InitMethodList,mode=G_MCRInitMethod,value=#"\"SVD;Random;Manual;NNDSVD;NNDSVD_quant;\""	
	SetVariable CompNumVar,pos={105,189},size={170,17}
	SetVariable CompNumVar,title="Number of components:",font="Arial",fSize=12
	SetVariable CompNumVar,limits={2,inf,1},value=dfr_MCR:G_MCRComponentsNum
	PopupMenu InitCMXList,pos={28,215},size={361,20},bodyWidth=230,disable=(G_MCRInitMethod!=3)*2,proc=MCRPopMenuProc
	PopupMenu InitCMXList,title="Init Concentration Matrix:",font="Arial",fSize=12
	PopupMenu InitCMXList,mode=1,popvalue=G_TempCMXWaveName,value=#"Wavelist(\"*\",\";\",\"DIMS:2\")"
	PopupMenu InitSMXList,pos={28,239},size={361,20},bodyWidth=260,disable=(G_MCRInitMethod!=3)*2,proc=MCRPopMenuProc
	PopupMenu InitSMXList,title="Init Spectral Matrix:",font="Arial",fSize=12
	PopupMenu InitSMXList,mode=1,popvalue=G_TempSMXWaveName,value=#"Wavelist(\"*\",\";\",\"DIMS:2\")"
	Button InitButton,pos={296,187},size={90,20},title="Init",font="Arial",proc=MCRInitButtonProc
	Button InitButton,fSize=12,fColor=(2,39321,1)
	
	//__________________
	// Optimize Group
	//__________________
	GroupBox MCROptGroup,pos={10,280},size={390,235}
	GroupBox MCROptGroup,title="OPTIMIZE",font="Arial",fSize=12,fStyle=1
	PopupMenu OptMethodList,pos={28,305},size={361,20},bodyWidth=270,proc=MCRPopMenuProc
	PopupMenu OptMethodList,title="Optimize method",font="Arial",fSize=12
	PopupMenu OptMethodList,mode=G_MCROptMethod,value=#"\"HALS;\""
	SetVariable ItrMaxVar,pos={28,330},size={110,17},title="Iteration:"
	SetVariable ItrMaxVar,font="Arial",fSize=12
	SetVariable ItrMaxVar,limits={1,inf,1},value=dfr_MCR:G_MCRItrNum
	CheckBox CheckRecordHist,pos={170,330},size={96,16}
	CheckBox CheckRecordHist,title="History Record",font="Arial",fSize=12,value=0
	SetVariable RecordHistVar,pos={280,330},size={110,17}
	SetVariable RecordHistVar,title="Interval:",font="Arial",fSize=12
	SetVariable RecordHistVar,limits={10,inf,10},value=dfr_MCR:G_MCRRecordHistNum
	Button PauseButton,pos={296,455},size={90,20},disable=1,title="Pause",proc=MCRPauseResumeButtonProc
	Button PauseButton,font="Arial",fSize=12
	SetVariable BetweenRunSecVar,pos={28,485},size={210,17},title="Seconds between iterations:"
	SetVariable BetweenRunSecVar,font="Arial",fSize=12
	SetVariable BetweenRunSecVar,limits={0.05,inf,0.05},value=dfr_MCR:G_MCRBetweenRunSec
	Button OptButton,pos={296,485},size={90,20},title="Do Analysis",proc=MCROptimizeButtonProc
	Button OptButton,font="Arial",fSize=12,fColor=(2,39321,1)	

	//__________________
	// Result Group
	//__________________
	GroupBox MCRResultGroup,pos={10,530},size={390,155}
	GroupBox MCRResultGroup,title="RESULT",font="Arial",fSize=12,fStyle=1
	Button ShowSp,pos={20,560},size={130,20},title="Show MCR Spectrum",proc=MCRButtonProc 
	Button ShowSp,font="Arial",fSize=12,disable=0
	PopupMenu ShowResCMXList,pos={170,560},size={100,20},bodyWidth=90,proc=MCRPopMenuProc
	PopupMenu ShowResCMXList,title="CMX:",font="Arial",fSize=10
	PopupMenu ShowResCMXList,mode=1,popvalue=G_ResCMXWaveName,value=#"Wavelist(\"*M_C*\",\";\",\"DIMS:2\",root:RHYME:MCR)"
	PopupMenu ShowResSMXList,pos={290,560},size={100,20},bodyWidth=90,proc=MCRPopMenuProc
	PopupMenu ShowResSMXList,title="SMX:",font="Arial",fSize=10
	PopupMenu ShowResSMXList,mode=1,popvalue=G_ResSMXWaveName,value=#"Wavelist(\"*M_S*\",\";\",\"DIMS:2\",root:RHYME:MCR)"
	Button ShowConc,pos={20,590},size={130,20},title="Show MCR Conc.",proc=MCRButtonProc 
	Button ShowConc,font="Arial",fSize=12
	Button ShowImg,pos={20,620},size={130,20},title="Show MCR Image",proc=MCRButtonProc 
	Button ShowImg,font="Arial",fSize=12
	SetVariable ImgRowSetVar,pos={160,590},size={65,17},title="Row:"
	SetVariable ImgRowSetVar,font="Arial",fSize=10,value=_NUM:60,limits={1,inf,1}
	SetVariable ImgColSetVar,pos={230,590},size={80,17},title="Column:"
	SetVariable ImgColSetVar,font="Arial",fSize=10,value=_NUM:60,limits={1,inf,1}
	SetVariable ImgLayerSetVar,pos={315,590},size={80,17},title="Layer:"
	SetVariable ImgLayerSetVar,font="Arial",fSize=10,value=_NUM:1,limits={1,inf,1}
	CheckBox CheckTransposeImg,pos={190,620},size={100,16}
	CheckBox CheckTransposeImg,title="Transpose Image: ",font="Arial",fSize=10,side=1,value=0
	CheckBox CheckMultiImg,pos={315,620},size={96,16}
	CheckBox CheckMultiImg,title="Multi Image: ",font="Arial",fSize=10,side=1,value=0
	Button ShowObj,pos={20,650},size={130,20},title="Show Obj. Function",proc=MCRButtonProc
	Button ShowObj,font="Arial",fSize=12
	Button SaveMCRRes,pos={296,650},size={90,20},title="Save Result",proc=MCRButtonProc
	Button SaveMCRRes,font="Arial",fSize=12,fColor=(2,39321,1)
End


Function DispInitPanel(comp_num)
	variable comp_num
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	SVAR G_MCRxWaveName = dfr_MCR:G_MCRxWaveName
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	WAVE obj = dfr_MCR:obj
	WAVE M_ST = dfr_MCR:M_ST
	WAVE xWave = $G_MCRxWaveName
	variable i
	
	//set run number to 0
	G_MCRRunNum = 0
	
	//Restrict window overlap (Recreate window)
	DoWindow/F winMCRAnalysisPanel
	variable wl,wt,wr,wb
	if(V_flag)
		getwindow  winMCRAnalysisPanel wsize
		wl=V_left; wt=V_top; wr=V_right; wb=V_bottom;
		killwindow/Z winMCRAnalysisPanel
	else
		wl=200; wt=100; wr=1100; wb=300;
	endif
	PauseUpdate; Silent 1		// building window...
	
	//___________
	// Host Panel
	//___________
	Newpanel /K=1 /W=(wl,wt,wr,wb)/FG=(FL,*,FR,*)  as "MCR Analysis Panel"
	RenameWindow $S_name, winMCRAnalysisPanel
	TitleBox StatusTitle title="Waiting.",pos={10,8},frame=0,fSize=12
	DefineGuide UG_MSR={FR,-60},UG_OBJR={FR,-590},UG_OBJB={FB,-200},UG_MSB={FB,-10},UG_MSL={FR,-570},UG_NBT={FB,-190}
	setwindow winMCRAnalysisPanel sizelimit = {600, 700, inf, inf}
	setwindow winMCRAnalysisPanel hook(winHook)= MCRWindowKillHook	//window hook
	
	//___________________________
	// Objective Function (Loss)
	//____________________________
	Display/W=(10,30,310,400)/FG=($"",$"",UG_OBJR,UG_OBJB)/HOST=# obj
	ModifyGraph rgb=(2,39321,1)
	ModifyGraph standoff=0
	ModifyGraph grid=1,minor=1,gridRGB=(1,39321,19939)
	ModifyGraph live=2	//for high-speed rewrite
	ModifyGraph UIControl=1028 //DRAG and axis control DISABLED
	SetAxis/A=2 left
	ValDisplay CurrentRunVal, pos={220,8},size={40,20},bodyWidth=40,title="Iteration:"
	ValDisplay CurrentRunVal, font="Arial",fSize=12,fstyle=1
	ValDisplay CurrentRunVal, value=#"root:RHYME:MCR:G_MCRRunNum" 
	RenameWindow #,Gobj
	SetActiveSubwindow ##
	
	//_______________
	// Notebooks
	//_______________
	NewNotebook /F=1/W=(10,410,310,590)/FG=($"",UG_NBT,UG_OBJR,UG_MSB)/N=nb0/HOST=#/OPTS=4
	Notebook winMCRAnalysisPanel#nb0 ,autosave=0,text="==MCR-ALS PARAMETER==\r" 
	RenameWindow #,nb0
	SetActiveSubwindow ##
	
	//___________________________
	// M_ST (Spectral Matrix)
	//___________________________
	Display/W=(330,10,840,590)/FG=(UG_MSL,$"",UG_MSR,UG_MSB)/HOST=#
	for(i=0;i<comp_num;i+=1)
		string axisName = "Axis" + num2str(i+1)
		AppendtoGraph/L=$axisName M_ST[][i] vs xWave
		SetAxis/A=2 $axisName 0,*
		ModifyGraph zero($axisName)=1
		ModifyGraph nticks($axisName) = 2 
		ModifyGraph lblMargin($axisName)=5
		ModifyGraph lblPosMode($axisName)=1
		ModifyGraph freePos($axisName)=0
		ModifyGraph fSize($axisName)=8
		ModifyGraph axisEnab($axisName)={(1/comp_num)*(comp_num-(i+1)),(1/comp_num)*(comp_num-(i+1))+(0.8/comp_num)}
		Label $axisName  "\\Z16\\f01"+num2str(i+1)
	endfor
	SetAxis/A/R bottom
	ModifyGraph standoff=0
	ModifyGraph fSize(bottom)=12
	ModifyGraph live=2	//for high-speed rewrite
	ModifyGraph UIControl=1028 //DRAG and axis control DISABLED
	Label Bottom "\Z16Raman shift / cm\S-1"
	//COLOR CHANGE
	String list =  TraceNameList("", ";", 1)
	list = listMatch(list, "*")
	ChangeColor(list)
	RenameWindow #,GS
	SetActiveSubwindow ##
End	


//_____________________________
// *** - Initialize ***
//_____________________________
Function MCRInitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	NVAR G_MCRComponentsNum = dfr_MCR:G_MCRComponentsNum 
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_MCRxWaveName = dfr_MCR:G_MCRxWaveName
	SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
	
	switch( ba.eventCode )
		case 2: // mouse up
			////LOAD VARIABLES AND WAVES////
			WAVE TrgtWv = $G_MCRTrgtWaveName
			WAVE xWave = $G_MCRxWaveName
			WAVE MaskImg = $G_MCRMaskWaveName

			duplicate/O TrgtWv temp_TrgtWv
			WAVE temp_TrgtWv
			//mask check
			controlinfo /W=$"winMCRAnalyzer" CheckApplyMask
			variable mask = V_Value
			if(mask==1)
					mask_2D_forMCR(temp_TrgtWv, MaskImg)
			endif	
			
			variable data_num = dimsize(temp_TrgtWv, 0)
			variable sp_num = dimsize(temp_TrgtWv, 1)
			
			////CHECK-PROCESS////
			//input > 0
			if(wavemin(TrgtWv)<0)
				DoAlert 0, "Error: Negative values found in input." 
				return 0
			endif	
			//Rank check
			if(min(data_num,sp_num,G_MCRcomponentsNum) != G_MCRcomponentsNum) 
				DoAlert 0, "Error: Rank too large." 
				return 0
			endif
			//axis check
			if(sp_num!=dimsize(xwave,0))
				DoAlert 0, "Error: The data points of xaxis and target wave are different." 
				return 0
			endif
			
			////INITIALIZE////
			Make/O/N=(200) dfr_MCR:obj = Nan	//Create temp. objective function
			switch(G_MCRInitMethod)
				case 1:
					InitSVD(temp_TrgtWv,G_MCRComponentsNum)
					break
				case 2:
					InitRandom(temp_TrgtWv,G_MCRComponentsNum)
					break
				case 3:
					InitManual(temp_TrgtWv,G_MCRComponentsNum)
					break
				case 4:
					InitByNNDSVD(temp_TrgtWv,G_MCRComponentsNum)
					break
				case 5:
					InitByNNDSVD_quant(temp_TrgtWv,G_MCRComponentsNum)
					break
			Endswitch
			
			
			////LOAD INITIALIZED WAVES////
			wave M_S0 = dfr_MCR:M_S0 // initial M_S wave (k x m)
			wave M_C0 = dfr_MCR:M_C0 // initial M_C wave (n x k)
			duplicate/O M_S0 dfr_MCR:M_ST
			duplicate/O M_S0 dfr_MCR:M_S
			WAVE M_ST = dfr_MCR:M_ST
			duplicate/O M_C0 dfr_MCR:M_C
			WAVE M_C = dfr_MCR:M_C
			matrixtranspose M_ST //transform for analysis
			
			
			//NOTE WAVES
			Notewave_Init()
			
			////DISPLAY ANALYSIS PANEL////
			DispInitPanel(G_MCRComponentsNum)
			Notebook_Init()
			
			break	
		case -1: // control being killed
			break
	endswitch

	return 0
End


//____________________________
// *** - Optimize ***
//____________________________
Function MCROptimizeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR V_running = dfr_MCR:V_running
	
	
	switch( ba.eventCode )
		case 2: // mouse up
		
			//Init window check
			DoWindow/F winMCRAnalysisPanel
			if(!V_flag)
				Doalert 0, "ERROR: Not Initialized."
				return 0
			endif	
			
			if(V_running)
				MCR_OptStop()
				Doalert 0, "Analysis stopped."
			else
				//Re-Initialized
				////LOAD INITIALIZED WAVES////
				wave M_S0 = dfr_MCR:M_S0 // initial M_S wave (k x m)
				wave M_C0 = dfr_MCR:M_C0// initial M_C wave (n x k)
				duplicate/O M_S0 dfr_MCR:M_ST
				WAVE M_ST = dfr_MCR:M_ST
				duplicate/O M_C0 dfr_MCR:M_C
				WAVE M_C = dfr_MCR:M_C
				matrixtranspose M_ST //transform for analysis
				
				//kill history waves
				KillHistoryWaves()
				
				MCR_OptStart()
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function MCRPauseResumeButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR V_paused = dfr_MCR:V_paused
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(V_paused)
				MCR_OptResume()
			else
				MCR_OptPause()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function MCR_OptStart()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	NVAR G_MCRItrNum = dfr_MCR:G_MCRItrNum
	
	NVAR V_running = dfr_MCR:V_running
	NVAR V_paused = dfr_MCR:V_paused
	
	//reset current run number
	G_MCRRunNum = 0
	
	//Create Objective function
	Make/O/N=(G_MCRItrNum) dfr_MCR:obj = Nan
	//add note to obj
	Notewave_ReInit_obj()
	
	//set runnning/paused parameter
	V_running = 1
	V_paused = 0
	
	//button control
	Button OptButton, win=$"winMCRAnalyzer",title="STOP",fColor=(65535,0,0)
	Button PauseButton, win=$"winMCRAnalyzer",disable=0	
	
	//Set status message
	TitleBox StatusTitle win=$"winMCRAnalysisPanel",title="Optimizing..."	
			
	//Disable Controls
	DisableControlForOpt()
		
	MCR_StartBackgroundTask()
End

Function MCR_OptStop()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR V_running = dfr_MCR:V_running
	NVAR V_paused = dfr_MCR:V_paused
	
	//set runnning/paused parameter
	V_running = 0
	V_paused = 0
	
	//button control
	Button OptButton, win=$"winMCRAnalyzer",title="Do Analysis",fColor=(2,39321,1)
	Button PauseButton, win=$"winMCRAnalyzer", title= "Pause",disable=1	
	
	//Set status message
	TitleBox StatusTitle win=$"winMCRAnalysisPanel",title="Stopped optimization."
	
	//duplicate and transpose M_ST
	duplicate/O dfr_MCR:M_ST dfr_MCR:M_S
	wave M_S = dfr_MCR:M_S
	matrixtranspose M_S
	
	//Enable Controls
	EnableControlForOpt()
	
	//note optimize conditions to notebook & waves
	Notewave_Opt()
	Notebook_Opt()
	
	//mask check for Reconstruction
	controlinfo /W=$"winMCRAnalyzer" CheckApplyMask
		variable mask = V_Value
		if(mask==1)
			SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
			WAVE MaskImg = $G_MCRMaskWaveName
			WAVE M_C = root:RHYME:MCR:M_C
			maskRe_2D_forMCR(M_C,MaskImg)
	endif	
	
	MCR_StopBackgroundTask()
End


Function MCR_OptResume()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)	
	NVAR V_paused = dfr_MCR:V_paused
	
	//set runnning/paused parameter
	V_paused = 0
	
	//DISABLE some CONTROLS 
	SetVariable BetweenRunSecVar win=$"winMCRAnalyzer",disable=2
	
	//button control
	Button PauseButton, win=$"winMCRAnalyzer", title= "Pause"
	
	//Set status message
	TitleBox StatusTitle win=$"winMCRAnalysisPanel",title="Resuming optimization..."
	
	MCR_StartBackgroundTask()
End

Function MCR_OptPause()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)	
	NVAR V_paused = dfr_MCR:V_paused
	
	//set runnning/paused parameter
	V_paused = 1
	
	//ENABLE some CONTROLS
	SetVariable BetweenRunSecVar win=$"winMCRAnalyzer",disable=0
	
	//button control
	Button PauseButton, win=$"winMCRAnalyzer", title= "Resume"
	
	//Set status message
	TitleBox StatusTitle win=$"winMCRAnalysisPanel",title="Optimization paused."
	
	MCR_StopBackgroundTask()
End



Function DisableControlForOpt()
	//WAVE SELECT
	PopupMenu Trgt2dWList win=$"winMCRAnalyzer",disable=2
	PopupMenu XaxisWList win=$"winMCRAnalyzer",disable=2
	PopupMenu MaskWList win=$"winMCRAnalyzer",disable=2
	//INITIALIZE
	PopupMenu InitMethodList win=$"winMCRAnalyzer",disable=2
	SetVariable CompNumVar win=$"winMCRAnalyzer",disable=2
	Button InitButton win=$"winMCRAnalyzer",disable=2
	PopupMenu InitCMXList win=$"winMCRAnalyzer",disable=2
	PopupMenu InitSMXList win=$"winMCRAnalyzer",disable=2
	//OPTIMIZE
	PopupMenu OptMethodList win=$"winMCRAnalyzer",disable=2
	SetVariable ItrMaxVar win=$"winMCRAnalyzer",disable=2
	CheckBox CheckRecordHist win=$"winMCRAnalyzer",disable=2
	SetVariable RecordHistVar win=$"winMCRAnalyzer",disable=2
	SetVariable BetweenRunSecVar win=$"winMCRAnalyzer",disable=2
End

Function EnableControlForOpt()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod	
	//WAVE SELECT
	PopupMenu Trgt2dWList win=$"winMCRAnalyzer",disable=0
	PopupMenu XaxisWList win=$"winMCRAnalyzer",disable=0
	PopupMenu MaskWList win=$"winMCRAnalyzer",disable=0
	//INITIALIZE
	PopupMenu InitMethodList win=$"winMCRAnalyzer",disable=0
	SetVariable CompNumVar win=$"winMCRAnalyzer",disable=0
	Button InitButton win=$"winMCRAnalyzer",disable=0
	PopupMenu InitCMXList win=$"winMCRAnalyzer",disable=(G_MCRInitMethod!=3)*2
	PopupMenu InitSMXList win=$"winMCRAnalyzer",disable=(G_MCRInitMethod!=3)*2
	//OPTIMIZE
	PopupMenu OptMethodList win=$"winMCRAnalyzer",disable=0
	SetVariable ItrMaxVar win=$"winMCRAnalyzer",disable=0
	CheckBox CheckRecordHist win=$"winMCRAnalyzer",disable=0
	SetVariable RecordHistVar win=$"winMCRAnalyzer",disable=0
	SetVariable BetweenRunSecVar win=$"winMCRAnalyzer",disable=0
End


//__________________________________________
// *** - Background Task for Optimization ***
//__________________________________________

Function MCR_StartBackgroundTask()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)	
	NVAR G_MCRBetweenRunSec = dfr_MCR:G_MCRBetweenRunSec
	Variable secondsBetweenRuns = G_MCRBetweenRunSec 
	Variable periodInTicks = 60 * secondsBetweenRuns
	CtrlNamedBackground MCROptimize, proc=MCR_OptTask, period=periodInTicks, start	
End

Function MCR_StopBackgroundTask()
	CtrlNamedBackground MCROptimize, stop
End

Function MCR_OptTask(s)				// This is the function that will be called periodically by the background task
	STRUCT WMBackgroundStruct &s
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCROptMethod = dfr_MCR:G_MCROptMethod
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	NVAR G_MCRItrNum = dfr_MCR:G_MCRItrNum
	
	G_MCRRunNum +=1
	
	//Optimize method
	switch(G_MCROptMethod)
		case 1:
			Optimize_HALS(G_MCRRunNum)
			break
	endswitch		
	
	
	if (G_MCRRunNum >= G_MCRItrNum)
		MCR_OptStop()
		TitleBox StatusTitle win=$"winMCRAnalysisPanel",title="Optimization finished."
		DoAlert 0,"Finished!"
	endif
	
	
	
	return 0	// Continue background task
End


//____________________________
// *** - Initialize Methods ***
//____________________________

static function InitSVD(input,k)
	wave input //2D matrix
	variable k //components_num
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	variable data_num = dimsize(input,0)
	variable sp_num = dimsize(input,1)
	
	////MAIN-PROCESS////
	//SVD process
	matrixsvd input  
	wave M_VT,M_U,W_W
	
	//C matrix (n x k) ...SVD components from M_U (Transformed to absolute value)
	duplicate/O M_U dfr_MCR:M_C0 
	wave M_C0 = dfr_MCR:M_C0
	DeletePoints k, (data_num - k) , M_C0
	M_C0 = abs(M_C0)
	matrixtranspose M_C0

	//S matrix (k * m) ... SVD components from M_VT (Transformed to absolute value)
	duplicate/O M_VT dfr_MCR:M_S0
	wave M_S0 = dfr_MCR:M_S0
	deletepoints k, (sp_num - k), M_S0
	M_S0 = abs(M_S0)
	
	killwaves M_U,W_W,M_VT
end


static function InitRandom(input,k)
	wave input //2D matrix
	variable k //components_num
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	variable data_num = dimsize(input,0)
	variable sp_num = dimsize(input,1)
	variable i = 0 //for loop	

	
	////MAIN-PROCESS////	
	//C matrix (n x k) ... All 0.01
	make/O/N=(data_num,k) dfr_MCR:M_C0 = 0.01
	wave M_C0 = dfr_MCR:M_C0
	
	//S matrix (k * m) ... random components of input
	make/O/N=(k,sp_num) dfr_MCR:M_S0
	wave M_S0 = dfr_MCR:M_S0
	variable rdm
	for(i=0;i<k;i+=1)
		//rand
		rdm = round(abs(enoise(data_num-1)))
		M_S0[i][] = input[rdm][q]
	endfor
end

static function InitManual(input,k)
	wave input //2D matrix
	variable k //components_num
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	variable data_num = dimsize(input,0)
	variable sp_num = dimsize(input,1)

	////MAIN-PROCESS////
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	
	wave C_manual = $G_TempCMXWaveName	//C matrix (n x k) ... Manual
	wave S_manual = $G_TempSMXWaveName	//S matrix (k * m) ... Manual
	
	//check matrix size
	if(DimSize(C_manual,0)!=data_num||DimSize(C_manual,1)!=k)
		Doalert 0, "Matrix size error."
		abort
	endif
	
	//check matrix size
	if(DimSize(S_manual,0)!=k||DimSize(S_manual,1)!=sp_num)
		Doalert 0, "Matrix size error."
		abort
	endif
	
	duplicate/O C_manual dfr_MCR:M_C0
	duplicate/O S_manual dfr_MCR:M_S0

end


static function InitByNNDSVD(input,k) 
	// [Reference]===================
	// C. Boutsidis and E. Gallopoulos, "SVD based initialization: A head start for nonnegative matrix factorization",  
	// Pattern Recognition, 41(4), 1350–1362, 2008.
	// ==============================
	
	wave input //2D matrix
	variable k //components_num

	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	variable data_num = dimsize(input,0)
	variable sp_num = dimsize(input,1)
	variable i = 0 //for loop	
	
	////MAIN-PROCESS////
	//Make initial matrix
	make/O/N=(data_num,k) dfr_MCR:M_C0 = 0
	wave M_C0 = dfr_MCR:M_C0
	make/O/N=(k,sp_num) dfr_MCR:M_S0 = 0
	wave M_S0 = dfr_MCR:M_S0
	
	//SVD process
	matrixsvd input  
	wave M_VT,M_U,W_W	
	
	//Divide into cases based on the sign of the mean of the spectrum of the 0th singular component
	matrixOp/O/FREE U0ave = mean(row(M_VT,0))
	if(U0ave[0]>=0)
		M_S0[0][] = sqrt(W_W[0]) * M_VT[0][q]	
		M_C0[][0] = sqrt(W_W[0]) * M_U[p][0]		
	else
		M_S0[0][] = sqrt(W_W[0]) * M_VT[0][q] * -1 
		M_C0[][0] = sqrt(W_W[0]) * M_U[p][0] * -1
	endif	
	
		
	for(i=1;i<k;i+=1)
		MatrixOP/O/FREE s_p = (row(M_VT,i) + abs(row(M_VT,i))) / 2
		MatrixOP/O/FREE c_p = (col(M_U,i) + abs(col(M_U,i))) / 2
		MatrixOP/O/FREE s_n = (row(M_VT,i) - abs(row(M_VT,i))) / (-2)
		MatrixOP/O/FREE c_n = (col(M_U,i) - abs(col(M_U,i))) / (-2)	
		
		Redimension/N=(sp_num) s_n
		Redimension/N=(sp_num) s_p   
		
		MatrixOP/O/FREE ns_p = normP(s_p,2)
		MatrixOP/O/FREE nc_p = normP(c_p,2)
		MatrixOP/O/FREE ns_n = normP(s_n,2)
		MatrixOP/O/FREE nc_n = normP(c_n,2) 
		
		MatrixOP/O/FREE P_term = ns_p * nc_p
		MatrixOP/O/FREE N_term = ns_n * nc_n
		
		//choose which side to use
		if(P_term[0] >= N_term[0]) 
			M_S0[i][] = sqrt(W_W[i] * P_term[0]) * s_p[q] / ns_p[0]  
			M_C0[][i] = sqrt(W_W[i] * P_term[0]) * c_p[p] / nc_p[0]	
		else
			M_S0[i][] = sqrt(W_W[i] * N_term[0]) * s_n[q] / ns_n[0]	
			M_C0[][i] = sqrt(W_W[i] * N_term[0]) * c_n[p] / nc_n[0]	
		endif 		
	endfor
	////
	
	killwaves M_VT,M_U,W_W
end	


static function InitByNNDSVD_quant(input,k) 
	// ==============================
	// Based on NNDSVD, but the singular value scaling is applied directly to C
	// ==============================
	
	wave input //2D matrix
	variable k //components_num
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	variable data_num = dimsize(input,0)
	variable sp_num = dimsize(input,1)
	variable i = 0 //for loop	
	
	////MAIN-PROCESS////
	//Make initial matrix
	make/O/N=(data_num,k) dfr_MCR:M_C0 = 0
	wave M_C0 = dfr_MCR:M_C0
	make/O/N=(k,sp_num) dfr_MCR:M_S0 = 0
	wave M_S0 = dfr_MCR:M_S0
	
	//SVD process
	matrixsvd input  
	wave M_VT,M_U,W_W	
	
	//Divide into cases based on the sign of the mean of the spectrum of the 0th singular component
	matrixOp/O/FREE U0ave = mean(row(M_VT,0))
	if(U0ave[0]>=0)
		M_S0[0][] = M_VT[0][q]
		M_C0[][0] = W_W[0] * M_U[p][0]
	else
		M_S0[0][] = M_VT[0][q] * -1
		M_C0[][0] = W_W[0] * M_U[p][0] * -1
	endif	
	
		
	for(i=1;i<k;i+=1)
		MatrixOP/O/FREE s_p = (row(M_VT,i) + abs(row(M_VT,i))) / 2
		MatrixOP/O/FREE c_p = (col(M_U,i) + abs(col(M_U,i))) / 2
		MatrixOP/O/FREE s_n = (row(M_VT,i) - abs(row(M_VT,i))) / (-2)
		MatrixOP/O/FREE c_n = (col(M_U,i) - abs(col(M_U,i))) / (-2)	
		
		Redimension/N=(sp_num) s_n
		Redimension/N=(sp_num) s_p 
		
		MatrixOP/O/FREE ns_p = normP(s_p,2)
		MatrixOP/O/FREE nc_p = normP(c_p,2)
		MatrixOP/O/FREE ns_n = normP(s_n,2)
		MatrixOP/O/FREE nc_n = normP(c_n,2) 
		
		MatrixOP/O/FREE P_term = ns_p * nc_p
		MatrixOP/O/FREE N_term = ns_n * nc_n
		
		//choose which side to use
		if(P_term[0] >= N_term[0]) 
			M_S0[i][] = s_p[q] / ns_p[0]
			M_C0[][i] = W_W[i] * P_term[0] * c_p[p] / nc_p[0]
		else
			M_S0[i][] = s_n[q] / ns_n[0]
			M_C0[][i] = W_W[i] * N_term[0] * c_n[p] / nc_n[0]
		endif 		
	endfor
	////
	
	killwaves M_VT,M_U,W_W
	
end	

//____________________________
// *** - Optimize Methods ***
//____________________________
Function Optimize_HALS(runNumber)
	// [Reference]===================
	// A. Cichocki and A.H. Phan, “Fast local algorithms for large scale nonnegative matrix and tensor factorizations”,
	// IEICE transactions on fundamentals of electronics, communications and computer sciences, 92(3), 708-721, 2009.
	// ==============================

	variable runNumber
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	
	WAVE input = temp_TrgtWv
	WAVE M_ST = dfr_MCR:M_ST
	WAVE M_C = dfr_MCR:M_C
	WAVE obj = dfr_MCR:obj
	
	variable comp_num = dimsize(M_ST,1)
	variable data_num = dimsize(input, 0)
	variable sp_num = dimsize(input, 1)
	variable eps = 1e-07
	
	variable i,j	//variables for repeat
	
	//MAIN PROCESS
	//update C matrix
	MatrixOp/FREE/O M_XS = input x M_ST 
	MatrixOp/FREE/O M_ST2 = M_ST^T x M_ST
	
	for(i=0;i<comp_num;i+=1)
		//HALS
		MatrixOp/FREE/O M_C_1D  = col(M_Xs,i) - (M_C x col(M_ST2,i)) + (M_ST2[i][i] * col(M_C,i)) 
		M_C[][i] = M_C_1D[p]
		
		//non-negative constraint
		M_C = max(M_C,0) //replace negative values with 0
		
		//Normalize
		for(j=0;j<comp_num ;j+=1)
			MatrixOp/FREE/O M_Cb = col(M_C,j) 
			MatrixOp/FREE/O M_Ca = sqrt(M_Cb^T x col(M_C,j) + eps) 
			M_C[*][j] /= M_Ca[0]
		endfor	
	endfor 
	
	//update S matrix
	MatrixOp/FREE/O M_XC = input^T x M_C
	MatrixOp/FREE/O M_C2 = M_C^T x M_C

		
	for(i=0;i<comp_num;i+=1)
		//HALS
		MatrixOp/FREE/O M_ST_1D  = col(M_XC,i) - (M_ST x col(M_C2,i)) + (M_C2[i][i] * col(M_ST,i)) 
		M_ST[][i] = M_ST_1D[p]
	endfor 
	M_ST = max(M_ST,0)	//replace negative values with 0
			
	//calculate objective function
	MatrixOp/FREE/O X_est = M_C x M_ST^T //Reconstructed data matrix
	MatrixOp/FREE/O diff = frobenius(input - X_est) //Calculate Frobenius norm of error 
	MatrixOp/FREE/O diff = diff*diff/(data_num * sp_num)
	obj[runNumber-1] = diff[0]
	
	
	//History record
	controlinfo /W=$"winMCRAnalyzer" CheckRecordHist
	variable isHistRec = V_Value
	if(isHistRec==1)
		HistRecord(runNumber)
	endif	
End



//_____________________________
// *** - History Record ***
//_____________________________
function HistRecord(runNumber)
	variable runNumber
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	WAVE M_ST = dfr_MCR:M_ST
	WAVE M_C = dfr_MCR:M_C
	
	controlinfo /W=$"winMCRAnalyzer" RecordHistVar
	variable HistRecInterval = V_Value
	variable checkHistRec = mod(runNumber,HistRecInterval)
	if(checkHistRec==0)
		duplicate/O M_C $("root:RHYME:MCR:M_C_Hist_"+num2str(runNumber))
		wave M_C_hist = $("root:RHYME:MCR:M_C_Hist_"+num2str(runNumber))
		duplicate/O M_ST $("root:RHYME:MCR:M_S_Hist_"+num2str(runNumber))
		wave M_S_Hist = $("root:RHYME:MCR:M_S_Hist_"+num2str(runNumber))
		Matrixtranspose M_S_Hist
		Notewave_Hist(M_C_Hist,M_S_Hist)
	endif
End

Function KillHistoryWaves()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	string list = wavelist("*Hist*",";","",dfr_MCR)
	variable nmax = ItemsInList(list)
	string wvName
	variable i
	for(i=0;i<nmax;i+=1)
		wvName = StringFromList(i,list)
		wave hist_temp = dfr_MCR:$wvName
		killwaves hist_temp
	endfor
End

//____________________________
// *** - Show and Save Results ***
//____________________________
Function ShowRes_Sp()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	SVAR G_MCRxWaveName = dfr_MCR:G_MCRxWaveName
	wave xWave = $G_MCRxWaveName
	
	ControlInfo /W=$"winMCRAnalyzer" ShowResSMXList
	string M_S_PATH = "root:RHYME:MCR:"+S_Value
	wave M_S = $M_S_PATH
	
	variable comp_num = dimsize(M_S,0)
	variable sp_num = dimSize(M_S,1)
	variable sp_num_xWave = dimSize(xWave,0)
	
	//check error.
	if(sp_num!=sp_num_xWave)
		Doalert 0, "Size Error:The number of spectral points for xWave and S matrix are different."
		return 0
	endif
	
	Display/K=1/W=(310,10,710,610)/N=graphMCRSp
	variable i
	for(i=0;i<comp_num;i+=1)
		string axisName = "Axis" + num2str(i+1)
		AppendtoGraph/L=$axisName M_S[i][] vs xWave	
		SetAxis/A=2 $axisName 0,*
		ModifyGraph zero($axisName)=1
		ModifyGraph nticks($axisName) = 2 
		ModifyGraph lblMargin($axisName)=5
		ModifyGraph lblPosMode($axisName)=1
		ModifyGraph freePos($axisName)=0
		ModifyGraph axisEnab($axisName)={(1/comp_num)*(comp_num-(i+1)),(1/comp_num)*(comp_num-(i+1))+(0.8/comp_num)}
		Label $axisName  "\\Z20\\f01"+num2str(i+1)
		ModifyGraph lsize=1
		ModifyGraph mode=7,hbFill=5	// graph mode -> Fill
	endfor
	SetAxis/A/R bottom
	ModifyGraph standoff=0
	ModifyGraph fSize=12, axThick=2
	Label Bottom "\Z20Raman shift / cm\S-1"
	
	//COLOR CHANGE
	String list =  TraceNameList("", ";", 1)
	list = listMatch(list, "*")
	ChangeColor(list)
	
End	

Function ShowRes_Conc()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	ControlInfo /W=$"winMCRAnalyzer" ShowResCMXList
	string M_C_wvName = S_Value
	string M_C_PATH = "root:RHYME:MCR:"+M_C_wvName
	wave M_C = $M_C_PATH
	duplicate M_C dM_C
	
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	make/O/N=(1,data_num,comp_num) dfr_MCR:$("MCR_Conc_"+nameofwave(M_C))
	wave MCR_Img = dfr_MCR:$("MCR_Conc_"+nameofwave(M_C))
	MCR_Img = M_C
	DispMCRConc(MCR_Img,M_C)
End

Function ShowRes_Img()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	
	ControlInfo /W=$"winMCRAnalyzer" ShowResCMXList
	string M_C_wvName = S_Value
	string M_C_PATH = "root:RHYME:MCR:"+M_C_wvName
	wave M_C = $M_C_PATH
	
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	ControlInfo /W=$"winMCRAnalyzer" ImgRowSetVar
	variable row = V_value
	ControlInfo /W=$"winMCRAnalyzer" ImgColSetVar
	variable col = V_value
	ControlInfo /W=$"winMCRAnalyzer" ImgLayerSetVar
	variable Layer = V_value
	
	/////////////////////////////////
		controlinfo /W=$"winMCRAnalyzer" CheckTransposeImg
		if(V_Value==1)
		 variable temp_swap = col
		 col = row
		 row = temp_swap
		else
		endif
	////////////////////////////////
	
	if(Layer==1)
		make/O/N=(row,col,comp_num) dfr_MCR:$("MCR_Img_"+M_C_wvName)	//3D
		wave MCR_Img = dfr_MCR:$("MCR_Img_"+M_C_wvName)
		MCR_Img = M_C
		
	/////////////////////////////////
		controlinfo /W=$"winMCRAnalyzer" CheckTransposeImg
		if(V_Value==1)
		 matrixop MCR_Img2 = transposeVol(MCR_Img,5) 
		 duplicate/O MCR_Img2 MCR_Img
		 killwaves MCR_Img2
		else
		endif
	////////////////////////////////
		
		controlinfo /W=$"winMCRAnalyzer" CheckMultiImg
		if(V_Value==0)
			DispMCRImg_3D(MCR_Img,M_C)
		else
			DispMCRImg_Multi3D(MCR_Img,M_C)
		endif
	else
		Doalert 0, "4D image: Developing."
	endif
	
End

Function DispMCRConc(MCR_Img,M_C)
	wave MCR_Img, M_C
	
	variable data_num = dimsize(MCR_Img,1)
	variable comp_num = dimsize(MCR_Img,2)
	
	variable per = 1/comp_num
	variable gap = per/100
	
	display/K=1/N=graphMCRMImg/W=(50,50,300,650)	
	variable n
	string ImgName
	for(n=0;n<comp_num;n+=1)
		if(n==0)
			ImgName = nameofwave(MCR_Img)
		else
			ImgName = nameofwave(MCR_Img)+"#"+num2str(n)
		endif
		
		string bAxName = "b"+num2str(n)
		AppendImage/G=1/L=left/B=$bAxName MCR_Img
		ModifyGraph axisEnab($bAxName)={per*n,per*(n+1)-gap}
		ModifyImage $ImgName plane=n,ctab= {*,*,Geo32,0},ctabAutoscale=3
		
		//draw number
		SetDrawEnv xcoord= $bAxName,ycoord= abs,textrgb= (0,0,0),textxjust= 1,textyjust= 2,fstyle= 1,fsize= 18;DelayUpdate
		DrawText 0,35,num2str((n+1))
	endfor	

	ModifyGraph width={Plan,(data_num/9),b0,left}	
	ModifyGraph nticks=0,axThick=0
	ModifyGraph nticks(left)=5,axThick(left)=1.5,minor(left)=1,fSize(left)=8,fStyle(left)=1
	ModifyGraph margin(left)=42,margin(bottom)=8,margin(right)=8,margin(top)=56
	SetDrawEnv xcoord= abs,ycoord= abs,textyjust= 2
	DrawText 15,10,"MCR Concentration: " + nameofwave(M_C)
end



Function DispMCRImg_3D(MCR_Img,M_C)
	wave MCR_Img,M_C
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
		
	NewImage/G=1/K=1/N=graphMCRImg MCR_Img 
	ModifyGraph margin(top)=36
	ModifyGraph height={Plan,1,left,top}
	ModifyImage $nameofwave(MCR_Img) ctab= {*,*,Geo32,0},ctabAutoscale=3
	SetAxis/A left
	ModifyGraph gbRGB=(55535,55535,55535)       /////// Graph BG color
	SetDrawEnv xcoord= abs,ycoord= abs,textyjust= 2
	DrawText 15,10,"MCR Image: " + nameofwave(M_C)
	
	//draw line     // building ...
	variable i,j
	variable row = dimsize(MCR_Img,0)
	variable col = dimsize(MCR_Img,1)
	variable comp_num = dimsize(MCR_Img,2)
	variable datanum = 0
		for(i=0;i<row*col;i+=1)
			for(j=0;j<comp_num;j+=1)
				if(M_C[i][j] >= 0)
				datanum += 1
				endif
			endfor
		endfor
			
	if(row*col*comp_num == datanum)
	else
		ModifyGraph gbRGB=(55535,55535,55535)       /////// Graph BG color
	endif

	
	//setvariable
	SetVariable LayerSetVar,pos={190,5},size={50,14},proc= MCRSetVarProc
	SetVariable LayerSetVar,font="Arial",fSize=12
	SetVariable LayerSetVar,limits={0,DimSize(MCR_Img,2)-1,1},value=_NUM:0
End	

function DispMCRImg_Multi3D(MCR_Img,M_C)
	wave MCR_Img, M_C
	
	variable row = dimsize(MCR_Img,0)
	variable col = dimsize(MCR_Img,1)
	variable comp_num = dimsize(MCR_Img,2)
	
	variable box = ceil(sqrt(comp_num))
	variable per_r = 1/box
	variable per_c = 1/box
	if(comp_num<=(box^2-box))
		per_c = 1/(box-1)
	endif	
	variable gap = per_r/100
	
	display/K=1/N=graphMCRMImg/W=(50,50,650,650)	
	variable r,c
	string ImgName
	for(c=0;c<box;c+=1)
		for(r=0;r<box;r+=1)
		
			if(c*box+r>=comp_num)
				break
			endif	
			
			if(c*box+r==0)
				ImgName = nameofwave(MCR_Img)
			else
				ImgName = nameofwave(MCR_Img)+"#"+num2str(c*box+r)
			endif
			
			string rAxName = "r"+num2str(r); string cAxName = "c"+num2str(c)
			AppendImage/G=1/L=$cAxName/B=$rAxName MCR_Img
			ModifyGraph axisEnab($rAxName)={per_r*r,per_r*(r+1)-gap}
			ModifyGraph axisEnab($cAxName)={1-(per_c*(c+1)),1-(per_c*c)-gap}
			ModifyImage $ImgName plane=c*box+r,ctab= {*,*,Geo32,0},ctabAutoscale=3
			
			//draw number
			SetDrawEnv xcoord= $rAxName,ycoord= $cAxName,textrgb= (65535,65535,65535),textxjust= 0,textyjust= 2,fstyle= 1,fsize= 18;DelayUpdate
			DrawText 1,(col-2),num2str((c*box+r+1))
		endfor
	endfor
	
	//draw line     // building ...
	variable i,j
	variable datanum = 1
		for(i=0;i<row*col;i+=1)
			for(j=0;j<comp_num;j+=1)
				if(M_C[i][j] >= 0)
				datanum += 0
				endif
			endfor
		endfor
			
	if(row*col*comp_num == datanum)
	else
		ModifyGraph gbRGB=(55535,55535,55535)       /////// Graph BG color

		DrawLine 1,0,0,0
		DrawLine 0,1,0,0
		DrawLine 1,0,1,1
		DrawLine 0,1,1,1
			
		DrawLine per_r,0,per_r,1
		DrawLine 1-per_r,0,1-per_r,1
		DrawLine 0,per_c,1,per_c
		DrawLine 0,1-per_c,1,1-per_c
	endif	

	ModifyGraph height={Plan,1,c0,r0}	
	ModifyGraph nticks=0,axThick=0
	ModifyGraph margin(left)=5,margin(bottom)=5,margin(right)=5,margin(top)=28
	SetDrawEnv xcoord= abs,ycoord= abs,textyjust= 2
	DrawText 15,10,"MCR Image: " + nameofwave(M_C)
end

Function ShowRes_Obj()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	WAVE obj = dfr_MCR:obj
	
	//Restrict window overlap
	DoWindow/F graphObj
	if(V_flag)
		return 0
	endif
	PauseUpdate; Silent 1		// building window...
	
	Display/K=1 obj as "Objective Function"
	RenameWindow $S_name, graphObj
	ModifyGraph fSize=18,axThick=2,lblMargin(left)=5,standoff=0
	ModifyGraph grid=1,gridHair=1,gridRGB=(0,0,0)
	ModifyGraph rgb=(2,39321,1),lsize=2
	Label left "\\Z18Objective function"
	Label bottom "\\Z18Iteration number"
End

Function SaveMCRResult()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	wave M_C = dfr_MCR:M_C
	wave M_S = dfr_MCR:M_S
	
	if(!waveexists(M_C)||!waveexists(M_S))
		Doalert 0, "MCR result waves do not exist."
		return 0
	endif	
	
	string suffix
	prompt suffix,"Enter suffix of result M_C/M_S wave."
	Doprompt "Save MCR Results", suffix
	if(V_flag)
		return 0
	endif	
	
	if(waveexists($("M_C_"+suffix))||waveexists($("M_S_"+suffix)))
		Doalert 1, "Same name wave exists. Do you want to replace it?"
		if(V_flag!=1)
			return 0
		endif
	endif
		
	duplicate/O M_C $("M_C_"+suffix)
	duplicate/O M_S $("M_S_"+suffix)
End	
	


//____________________________
// *** - Note function ***
//____________________________

function Notewave_Init()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	NVAR G_MCRComponentsNum = dfr_MCR:G_MCRComponentsNum 
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	
	//load waves
	wave M_C0 = dfr_MCR:M_C0
	wave M_S0 = dfr_MCR:M_S0
	wave M_C = dfr_MCR:M_C
	wave M_S = dfr_MCR:M_S
	wave obj = dfr_MCR:obj
	wave M_ST = dfr_MCR:M_ST
	
	string text = "<Initialize>\r"
	text += "Input wave: " + G_MCRTrgtWaveName +";\r"
	controlinfo /W=$"winMCRAnalyzer" InitMethodList
	string initmethod = S_value
	text += "Initialize method: " + initmethod +";\r"
	text += "Number of components: " + num2str(G_MCRComponentsNum)+";\r"
	
	if(G_MCRInitMethod==3)
		text += "Init Concentration Matrix: " + G_TempCMXWaveName +";\r"
		text += "Init Spectral Matrix: " + G_TempSMXWaveName +";\r"
	endif
	
	
	Note/K M_C0, text
	Note/K M_S0, text
	Note/K M_C, text
	Note/K M_S, text
	Note/K obj, text
	Note/K M_ST, text
End

function Notewave_ReInit_obj()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	
	//load waves
	wave M_ST = dfr_MCR:M_ST
	wave obj = dfr_MCR:obj
	
	variable comp_num = dimsize(M_ST,1)
	string text = "<Initialize>\r"
	text += "Input wave: " + G_MCRTrgtWaveName +";\r"
	controlinfo /W=$"winMCRAnalyzer" InitMethodList
	string initmethod = S_value
	text += "Initialize method: " + initmethod +";\r"
	text += "Number of components: " + num2str(comp_num)+";\r"
	
	if(G_MCRInitMethod==3)
		text += "Init Concentration Matrix: " + G_TempCMXWaveName +";\r"
		text += "Init Spectral Matrix: " + G_TempSMXWaveName +";\r"
	endif
	
	Note/K obj, text
End

function Notewave_Opt()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	NVAR G_MCRItrNum = dfr_MCR:G_MCRItrNum
	
	//load waves
	wave M_C = dfr_MCR:M_C
	wave M_S = dfr_MCR:M_S
	wave obj = dfr_MCR:obj
	wave M_ST = dfr_MCR:M_ST
	
	string text = "<Optimize>\r"
	controlinfo /W=$"winMCRAnalyzer" OptMethodList
	string optmethod = S_value
	text += "Optimize method: " + optmethod +";\r"
	
	////////
	controlinfo /W=$"winMCRAnalyzer" CheckApplyMask
	variable mask = V_Value
	if(mask==1)
		SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
		text += "Mask: " + G_MCRMaskWaveName +";\r" // mask info
	endif
	///////

	
	text += "Iteration: " + num2str(G_MCRRunNum) + "/" + num2str(G_MCRItrNum) +";\r"
	
	Note M_C, text
	Note M_S, text
	Note obj, text
	Note M_ST, text
End

function Notewave_Hist(M_C_Hist,M_S_Hist)
	wave M_C_Hist,M_S_Hist
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	NVAR G_MCRItrNum = dfr_MCR:G_MCRItrNum
	
	
	string text = "<Optimize>\r"
	controlinfo /W=$"winMCRAnalyzer" OptMethodList
	string optmethod = S_value
	text += "Optimize method: " + optmethod +";\r"
	text += "Iteration: " + num2str(G_MCRRunNum) + "/" + num2str(G_MCRItrNum) +";\r"
	
	Note M_C_Hist, text
	Note M_S_Hist, text
End



function Notebook_Init()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	NVAR G_MCRComponentsNum = dfr_MCR:G_MCRComponentsNum 
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	
	string text = "<Initialize>\r"
	text += "Input wave: " + G_MCRTrgtWaveName +";\r"
	controlinfo /W=$"winMCRAnalyzer" InitMethodList
	string initmethod = S_value
	text += "Initialize method: " + initmethod +";\r"
	text += "Number of components: " + num2str(G_MCRComponentsNum)+";\r"
	
	if(G_MCRInitMethod==3)
		text += "Init Concentration Matrix: " + G_TempCMXWaveName +";\r"
		text += "Init Spectral Matrix: " + G_TempSMXWaveName +";\r"
	endif
	
	text += "\r"
	
	Notebook winMCRAnalysisPanel#nb0 ,text=text 
End

function Notebook_Opt()
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRRunNum = dfr_MCR:G_MCRRunNum
	NVAR G_MCRItrNum = dfr_MCR:G_MCRItrNum
	
	string text = "<Optimize>\r"
	controlinfo /W=$"winMCRAnalyzer" OptMethodList
	string optmethod = S_value
	text += "Optimize method: " + optmethod +";\r"
	
	////////
	controlinfo /W=$"winMCRAnalyzer" CheckApplyMask
	variable mask = V_Value
	if(mask==1)
		SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
		text += "mask: " + G_MCRMaskWaveName +";\r" // mask info
	endif
	///////
	
	text += "Iteration: " + num2str(G_MCRRunNum) + "/" + num2str(G_MCRItrNum) +";\r"

	text += "\r"
	
	//If already optimized, select the text about optimization
	Notebook winMCRAnalysisPanel#nb0, findText={"<Optimize>",9},selection={startOfParagraph, endOfFile}
	
	Notebook winMCRAnalysisPanel#nb0 ,text=text 
	
End

//____________________________
// *** - Hook function ***
//____________________________

Function MCRWindowKillHook(s)
	STRUCT WMWinHookStruct &s
	
	strswitch(s.winname)
		case "winMCRAnalysisPanel":
			strswitch(s.eventName)
				case "killVote":	// Analysis window killed
					DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
					Variable status = DataFolderRefStatus(dfr_MCR)
					if (status == 1)
						NVAR V_running = dfr_MCR:V_running
						if (V_running)
							Doalert 0, "Analysis window is being killed. Optimization is running but will now be stopped."
							MCR_OptStop()
						endif
					endif	
					break
		
			endswitch
			break
	endswitch
	
	return 0		
End


static Function AfterFileOpenHook(refNum, file, pathName, type, creator, kind)
	Variable refNum,kind
	String file, pathName, type, creator
	
	if (kind==1 || kind==2)				// Experiment just opened?
		DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
		Variable status = DataFolderRefStatus(dfr_MCR)
		if (status == 1)
			NVAR V_running = dfr_MCR:V_running
			if (V_running)
				DoAlert 0, "Experiment was saved with optimization running. It is now stopped."	
				MCR_OptStop()
				DoWindow/F winMCRAnalysisPanel
				if(V_flag)
					TitleBox StatusTitle title="Waiting."
				endif	
			endif
		endif
	endif
	return 0	// Igor ignores this
End

// This function makes sure acquisition is stopped when the current experiment is killed.
static Function IgorBeforeNewHook(igorApplicationNameStr)
	String igorApplicationNameStr

	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	Variable status = DataFolderRefStatus(dfr_MCR)
	if (status == 1)
		NVAR V_running = dfr_MCR:V_running
		if (V_running)
			DoAlert 0, "Experiment is being killed. Optimization is running but will now be stopped."
			MCR_OptStop()
		endif
	endif
	
	return 0	// Igor ignores this
End


// This function makes sure acquisition is stopped when Igor is quitting.
static Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	Variable unsavedExp, unsavedNotebooks, unsavedProcedures

	DFREF  dfr_MCR = $(RHYME_PATH + MCR_PATH)
	Variable status = DataFolderRefStatus(dfr_MCR)
	if (status == 1)
		NVAR V_running = dfr_MCR:V_running
		if (V_running)
			DoAlert 0, "Igor is quitting. Optimization is running but will now be stopped."
			MCR_OptStop()
			DoWindow/F winMCRAnalysisPanel
			if(V_flag)
				TitleBox StatusTitle title="Waiting."
			endif	
		endif
	endif
	
	return 0	// Proceed with normal quit process
End


//____________________________
// *** - Manual function ***
//____________________________

Function Manual_ShowRes_Sp(M_S,xWave)
	wave M_S,xWave
	
	variable comp_num = dimsize(M_S,0)
	variable sp_num = dimSize(M_S,1)
	variable sp_num_xWave = dimSize(xWave,0)
	
	//check error.
	if(sp_num!=sp_num_xWave)
		Doalert 0, "Size Error:The number of spectral points for xWave and S matrix are different."
		return 0
	endif
	
	Display/K=1/W=(310,10,710,610)
	variable i
	for(i=0;i<comp_num;i+=1)
		string axisName = "Axis" + num2str(i+1)
		AppendtoGraph/L=$axisName M_S[i][] vs xWave	
		SetAxis/A=2 $axisName 0,*
		ModifyGraph zero($axisName)=1
		ModifyGraph nticks($axisName) = 2 
		ModifyGraph lblMargin($axisName)=5
		ModifyGraph lblPosMode($axisName)=1
		ModifyGraph freePos($axisName)=0
		ModifyGraph axisEnab($axisName)={(1/comp_num)*(comp_num-(i+1)),(1/comp_num)*(comp_num-(i+1))+(0.8/comp_num)}
		Label $axisName  "\\Z20\\f01"+num2str(i)
		ModifyGraph lsize=2
		ModifyGraph mode=7,hbFill=4	// graph mode -> Fill
	endfor
	SetAxis/A/R bottom
	ModifyGraph standoff=0
	ModifyGraph fSize=12, axThick=2
	Label Bottom "\Z20Raman shift / cm\S-1"
	
	//COLOR CHANGE
	String list =  TraceNameList("", ";", 1)
	list = listMatch(list, "*")
	ChangeColor(list)
End	

Function Manual_ShowRes_Conc(M_C)
	wave M_C
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	make/O/N=(1,data_num,comp_num) $("MCR_Img_2D_"+nameofwave(M_C))
	wave MCR_Img = $("MCR_Img_2D_"+nameofwave(M_C))
	MCR_Img = M_C
	DispMCRConc(MCR_Img,M_C)

End

Function Manual_ShowRes_Img(M_C,row,col,layer)
	wave M_C
	variable row,col,layer
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	//check error.
	if(row*col*layer!=data_num)
		Doalert 0, "Size Error."
		return 0
	endif
	
		
	if(Layer==1)
		make/O/N=(row,col,comp_num) $("MCR_Img_"+nameofwave(M_C))	//3D
		wave MCR_Img = $("MCR_Img_"+nameofwave(M_C))
		MCR_Img = M_C
		DispMCRImg_3D(MCR_Img,M_C)
	else
		Doalert 0, "4D image: Developing."	
	endif
	
End

Function Manual_ShowRes_MImg(M_C,row,col,layer)
	wave M_C
	variable row,col,layer
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	//check error.
	if(row*col*layer!=data_num)
		Doalert 0, "Size Error."
		return 0
	endif
	
	if(Layer==1)
		make/O/N=(row,col,comp_num) $("MCR_Img_"+nameofwave(M_C))	//3D
		wave MCR_Img = $("MCR_Img_"+nameofwave(M_C))
		MCR_Img = M_C
		DispMCRImg_Multi3D(MCR_Img,M_C)
	else
		Doalert 0, "4D image: Developing."	
	endif
	
End


Function Manual_ShowRes_MImg_stack(M_C,row,col,layer)
	wave M_C
	variable row,col,layer
	variable data_num = dimSize(M_C,0)
	variable comp_num = dimsize(M_C,1)
	
	//check error.
	if(row*col*layer!=data_num)
		Doalert 0, "Size Error."
		return 0
	endif
	
	if(Layer==1)
		make/O/N=(row,col,comp_num) $("MCR_Img_"+nameofwave(M_C))	//3D
		wave MCR_Img = $("MCR_Img_"+nameofwave(M_C))
		MCR_Img = M_C
		DispMCRImg_Multi3D_stack(MCR_Img,M_C)
	else
		Doalert 0, "4D image: Developing."	
	endif
	
End

function DispMCRImg_Multi3D_stack(MCR_Img,M_C)
	wave MCR_Img, M_C
	
	variable row = dimsize(MCR_Img,0)
	variable col = dimsize(MCR_Img,1)
	variable comp_num = dimsize(MCR_Img,2)
	
	variable per = 1/comp_num
	variable gap = per/100
	
	display/K=1/N=graphMCRMImg/W=(50,50,250,250)	
	variable n
	string ImgName
	for(n=0;n<comp_num;n+=1)
		if(n==0)
			ImgName = nameofwave(MCR_Img)
		else
			ImgName = nameofwave(MCR_Img)+"#"+num2str(n)
		endif
		
		string bAxName = "b"+num2str(n)
		AppendImage/G=1/L=left/B=$bAxName MCR_Img
		ModifyGraph axisEnab($bAxName)={per*n,per*(n+1)-gap}
		ModifyImage $ImgName plane=n,ctab= {*,*,Geo32,0},ctabAutoscale=3
		
		//draw number
		SetDrawEnv xcoord= $bAxName,ycoord= left,textrgb= (65535,65535,65535),textxjust= 0,textyjust= 2,fstyle= 1,fsize= 18;DelayUpdate
		DrawText 1,(col-2),num2str((n))
	endfor	

	ModifyGraph width={Plan,1,b0,left}	
	ModifyGraph nticks=0,axThick=0
	ModifyGraph margin(left)=5,margin(bottom)=5,margin(right)=5,margin(top)=28
	SetDrawEnv xcoord= abs,ycoord= abs,textyjust= 2
	DrawText 15,10,"MCR Image: " + nameofwave(M_C)
end

	

//_____________________________
// *** - Color Change ***
//_____________________________
Static Function ChangeColor(list)
	String list
	Variable nmax	
	String wvName
	Variable r, g, b
	Variable i
	Variable hue, light, saturation
	Silent 1
	nmax = ItemsInList(list)
	for( i = 0; i < nmax; i += 1)
		hue = (nmax == 1) ? 240 : ((nmax <= 5) ? 240 : 270)*i/(nmax-1)
		light = 0.5 - 0.15*exp(-((hue-120)/50)^2)
		saturation = 1
		HLS2RGB( hue, light, saturation, r, g, b)
		wvName = StringFromList(i, list)
		ModifyGraph RGB($wvName) = (r*65535, g*65535, b*65535)

	endfor
	return 0
End

Static Function HLS2RGB(h, l, s, red, green, blue) //hue:[0 360] lightness*[0 1] saturation[0 1] rgb[0 1]
	Variable h, l, s
	Variable &red, &green, &blue
	Variable maximum, minimum
	if(s == 0)
		red = l; green = l; blue = l
		return 0
	endif
	maximum = (l <= 0.5) ? l*(1+s) : l*(1-s) + s
	minimum = 2*l - maximum
	substitute(red, mod(h +120, 360), maximum, minimum)
	substitute(green, h, maximum, minimum)
	substitute(blue, mod(h +240, 360), maximum, minimum)
End

Static Function substitute(value, a, maximum, minimum)
	Variable &value
	Variable a, maximum ,minimum
	if(a < 60)
		value = minimum+(maximum - minimum)*a/60
	elseif(a < 180)
		value = maximum
	elseif(a < 240)
		value = minimum+(maximum - minimum)*(240-a)/60
	else
		value = minimum
	endif
End



//_____________________________
// *** - Mask ***
//_____________________________
function mask_2D_forMCR(temp_input_2D,maskImg) // mask:0or1
	wave temp_input_2D, maskImg
	variable data_num = DimSize(temp_input_2D,0)
	variable SP_num = DimSize(temp_input_2D,1) 
	variable temp_value
	
	make/O/N=(data_num) maskImg_1d
	maskImg_1d = maskImg
	
	InsertPoints/M=0 0,1, temp_input_2D
	InsertPoints/M=0 0,1, maskImg_1d
	maskImg_1d[0]=1
	
	variable i
	for(i=0;i<data_num+1;i+=1)
		temp_value = maskImg_1d[i]
				if(temp_value == 0)
					DeletePoints/M=0 i,1, temp_input_2D
					DeletePoints/M=0 i,1, maskImg_1d
					 i -= 1
					 data_num -= 1
				endif
	endfor
	DeletePoints/M=0 0,1, temp_input_2D
	DeletePoints/M=0 0,1, maskImg_1d
end

function maskRe_2D_forMCR(input_M_C,maskImg) // mask:0or1
	wave input_M_C, maskImg
	variable row = DimSize(maskImg,0) 
	variable col = DimSize(maskImg,1) 
	variable data_num = row*col
	variable temp_V
	
	WAVE output = input_M_C
	make/O/N=(data_num) maskImg_1d
	
	variable i,j,k
	for(i=0;i<col;i+=1)
		for(j=0;j<row;j+=1)
			temp_V = maskImg[j][i][0]
			maskImg_1d[k] = temp_V
			k += 1
		endfor
	endfor	
	
	
	InsertPoints/M=0 0,1, output
	InsertPoints/M=0 0,1, maskImg_1d
	maskImg_1d[0]=1
	
	variable m,n
	for(m=0;m<data_num+1;m+=1)
			temp_V = maskImg_1d[m]
				if(temp_V == 0)
					InsertPoints/M=0 m,1, output					
					output[m][] = NaN
				endif
	endfor
	DeletePoints/M=0 0,1, output
	DeletePoints/M=0 0,1, maskImg_1d
end

//____________________________
// *** - Controls ***
//____________________________


Function MCRButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			strswitch(ba.ctrlname)
				case "ShowSp":
					switch( ba.eventCode )
						case 2: // mouse up
							ShowRes_Sp()
							break
						case -1: // control being killed
							break
					endswitch
					break
				case "ShowImg":
					switch( ba.eventCode )
						case 2: // mouse up
							ShowRes_Img()
							break
						case -1: // control being killed
							break
					endswitch
					break
				case "ShowConc":
					switch( ba.eventCode )
						case 2: // mouse up
							ShowRes_Conc()
							break
						case -1: // control being killed
							break
					endswitch
					break
				case "showObj":
					switch( ba.eventCode )
						case 2: // mouse up
							ShowRes_Obj()
							break
						case -1: // control being killed
							break
					endswitch
					break
					
				case "SaveMCRRes":
					switch( ba.eventCode )
						case 2: // mouse up
							SaveMCRResult()
							break
						case -1: // control being killed
							break
					endswitch
					break
			endswitch			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function MCRSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			strswitch(sva.ctrlName)
			case "LayerSetVar":	
				ModifyImage/W=$(sva.win) '' plane=sva.dval
				break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function MCRPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	DFREF dfr_MCR = $(RHYME_PATH + MCR_PATH)
	NVAR G_MCRInitMethod = dfr_MCR:G_MCRInitMethod
	NVAR G_MCROptMethod = dfr_MCR:G_MCROptMethod
	SVAR G_MCRTrgtWaveName = dfr_MCR:G_MCRTrgtWaveName
	SVAR G_MCRxWaveName = dfr_MCR:G_MCRxWaveName
	SVAR G_MCRMaskWaveName = dfr_MCR:G_MCRMaskWaveName
	SVAR G_TempCMXWaveName = dfr_MCR:G_TempCMXWaveName
	SVAR G_TempSMXWaveName = dfr_MCR:G_TempSMXWaveName
	SVAR G_ResSMXWaveName = dfr_MCR:G_ResSMXWaveName
	SVAR G_ResCMXWaveName = dfr_MCR:G_ResCMXWaveName
	
	strswitch( pa.ctrlname )
		case "Trgt2dWList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_MCRTrgtWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
			
			
		case "XaxisWList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_MCRxWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
			
		case "MaskWList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_MCRMaskWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
		
		case "InitCMXList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_TempCMXWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
			
		case "InitSMXList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_TempSMXWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
			
			
		case "InitMethodList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_MCRInitMethod = pa.popnum
					PopupMenu InitCMXList, win=$"winMCRAnalyzer", disable=2
					PopupMenu InitSMXList, win=$"winMCRAnalyzer", disable=2
					// Make C/S matrix input available when manual menu is selected
					if(G_MCRInitMethod==3)
						PopupMenu InitCMXList, win=$"winMCRAnalyzer", disable=0
						PopupMenu InitSMXList, win=$"winMCRAnalyzer", disable=0
					endif
					
					break
				case -1: // control being killed
					break
			endswitch
			break
		case "OptMethodList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_MCROptMethod = pa.popnum
					break
				case -1: // control being killed
					break
			endswitch
			break
		case "ShowResSMXList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_ResSMXWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
		case "ShowResCMXList":
			switch( pa.eventCode )
				case 2: // mouse up
					G_ResCMXWaveName = pa.popstr
					break
				case -1: // control being killed
					break
			endswitch
			break
	endswitch		
	return 0
End

