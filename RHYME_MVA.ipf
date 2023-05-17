#pragma TextEncoding 	= "UTF-8"
#pragma rtGlobals		= 3				
#pragma IgorVersion 	= 9.01
#pragma ModuleName		= RhymeIgorMVA
#pragma version			= 1.00
#pragma DefaultTab		= {3,20,4}		

//____________________________________________________________________________
//	Rhyme-Igor: Raman Hyperspectral image Management Environment for Igor Pro
//									= Add-On = 
//							MultiVariate Analysis Pack
//
//	Written by Ren Shibuya 
//	Github Repository: https://github.com/siettela/rhyme-igor
//	
//	2023-05-18 - ver. 1.00: Initial public release (PCA).
//____________________________________________________________________________


//###################################################### MVA MAIN FUNCTIONS ####################################################################################

//_______________________________________
// *** Set Static Constants and Menu ***
//________________________________________

static strconstant RHYME_PATH = "root:RHYME"
static strconstant PARAMS_PATH = ":Params"	// Parameter of main analyze panel

static strconstant PCA_PATH = ":PCA"	// Parameter of Principle Component Analysis(PCA).
static strconstant Clustering_PATH = ":Clustering"	// Parameter of Clustering Analysis (HCA, k-means etc).
static strconstant MCR_PATH = ":MCR"	// Parameter of Multi Curve Resolution(MCR). 
static strconstant TwoDCOS_PATH = ":TwoDCOS"	// Parameter of Two-Dimensional Correlation Spectroscopy(2D-COS).

Menu "Rhyme"
	"-"
	Submenu "Multivariate Analysis"
		"PCA",/Q, LaunchPCAPanel()
		//"Clustering",/Q, LaunchClusteringPanel()
		//"MCR",/Q, LaunchMCRPanel()
		//"2D-COS",/Q, Launch2DCOSPanel()
	end
	"-"
End		

//__________________________________________________________________
// *** Make Data Folder and Global Variables, Strings and Waves ***
//__________________________________________________________________
Static Function AfterCompiledHook()	//Make Folder and Variables when this procedure is compiled.
	PrepareDataFolder()
	PrepareGlobalVars()

End

Static Function PrepareDataFolder()	//Make data folder for multivariate analysis parameters if not exist.
	if(!DataFolderExists(RHYME_PATH))
		NewDataFolder $RHYME_PATH
	endif
	
	if(!DataFolderExists(RHYME_PATH + PCA_PATH))	//Principle Component Analysis(PCA)
		NewDataFolder $(RHYME_PATH + PCA_PATH)
	endif
	
	//developing
//	if(!DataFolderExists(RHYME_PATH + PCA_PATH))	//Clustering Analysis (HCA, k-means etc)
//		NewDataFolder $(RHYME_PATH + Clustering_PATH)
//	endif
//	if(!DataFolderExists(RHYME_PATH + PCA_PATH))	//Multi Curve Resolution(MCR)
//		NewDataFolder $(RHYME_PATH + MCR_PATH)
//	endif
//	if(!DataFolderExists(RHYME_PATH + PCA_PATH))	//Two-Dimensional Correlation Spectroscopy(2D-COS)
//		NewDataFolder $(RHYME_PATH + TwoDCOS_PATH)
//	endif

End

Static Function PrepareGVariable(Path,gVarName, DefaultVal)	// Make and initialize a global variable if not exist.
	String Path
	String gVarName
	Variable DefaultVal
	NVAR gVar = $(RHYME_PATH+Path+":"+gVarName)
	if(!NVAR_Exists(gVar))
		Variable/G $(RHYME_PATH+Path+":"+gVarName) = DefaultVal
	endif
End

Static Function PrepareGString(Path,gStrName, DefaultStr)	// Make and initialize a global string if not exist.
	String Path
	String gStrName
	String DefaultStr
	SVAR gStr = $(RHYME_PATH+Path+":"+gStrName)
	if(!SVAR_Exists(gStr))
		String/G $(RHYME_PATH+Path+":"+gStrName) = DefaultStr
	endif
End

Static Function PrepareGWave(Path,gWaveName,DefaultRow,DefaultCol,DefaultLayer,DefaultChunk) // Make and initialize a global wave if not exist.
	String Path
	String gWaveName
	Variable DefaultRow,DefaultCol,DefaultLayer,DefaultChunk
	WAVE gWave = $(RHYME_PATH+Path+":"+gWaveName)
	if(!WaveExists(gWave))
		Make/N=(DefaultRow,DefaultCol,DefaultLayer,DefaultChunk) $(RHYME_PATH+path+":"+gWaveName)
	endif	
End


Static Function PrepareGlobalVars()	//Make global variables required for multivariate analysis.

	//++++++++++++++++++++ PCA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	PrepareGVariable(PCA_PATH,"G_SCOREnum_x",1)
	PrepareGVariable(PCA_PATH,"G_SCOREnum_y",2)
	PrepareGVariable(PCA_PATH,"G_SCOREnum_z",3)
	PrepareGVariable(PCA_PATH,"G_MSCOREnum",2)
	PrepareGVariable(PCA_PATH,"G_LOADINGregionnum",4)
	PrepareGVariable(PCA_PATH,"G_DataLayernum",1)
	PrepareGVariable(PCA_PATH,"G_ScalingMethod",0)	//0:Whole point, 1:each point
	PrepareGVariable(PCA_PATH,"G_isCenteringValid",1)	//0:inValid, 1:Valid
	PrepareGVariable(PCA_PATH,"G_isScalingValid",1)	//0:inValid, 1:Valid
	PrepareGVariable(PCA_PATH,"G_is3dplotValid",0)	//0:inValid, 1:Valid
	PrepareGVariable(PCA_PATH,"G_isMaskValid",0)	//0:inValid, 1:Valid
	
	PrepareGString(PCA_PATH,"G_PCAWaveName","None")
	PrepareGString(PCA_PATH,"G_MaskWaveName","None")
	PrepareGString(PCA_PATH,"G_AnalyzedPCAWaveName","None")
	
	//++++++++++++++++++++ Clustering ++++++++++++++++++++++++++++++++++++++++++++++++++++
		//developing
	//++++++++++++++++++++ MCR +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//developing
	//++++++++++++++++++++ 2D-COS +++++++++++++++++++++++++++++++++++++++++++++++++++++++
		//developing
End


//_____________________________
// *** ====PCA====  ***
//_____________________________
//_____________________________
// *** - Launch Panel ***
//_____________________________
Function LaunchPCAPanel()
	//Load global variables
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_SCOREnum_x = dfr_PCA: G_SCOREnum_x
	NVAR G_SCOREnum_y = dfr_PCA: G_SCOREnum_y
	NVAR G_SCOREnum_z = dfr_PCA: G_SCOREnum_z
	NVAR G_MSCOREnum = dfr_PCA: G_MSCOREnum
	NVAR G_LOADINGregionnum= dfr_PCA: G_LOADINGregionnum
	NVAR G_ScalingMethod= dfr_PCA: G_ScalingMethod
	NVAR G_isCenteringValid= dfr_PCA: G_isCenteringValid
	NVAR G_isScalingValid= dfr_PCA: G_isScalingValid
	NVAR G_is3dplotValid= dfr_PCA: G_is3dplotValid
	NVAR G_isMaskValid= dfr_PCA: G_isMaskValid
	
	SVAR G_PCAWaveName = dfr_PCA: G_PCAWaveName
	G_PCAWaveName = stringFromList(0,Wavelist("*",";","DIMS:2"))
	
	SVAR G_MaskWaveName = dfr_PCA: G_MaskWaveName
	G_MaskWaveName = stringFromList(0,Wavelist("*",";","DIMS:1"))
	
	SVAR G_AnalyzedPCAWaveName = dfr_PCA: G_AnalyzedPCAWaveName
	
	//restrict window overlap
	DoWindow/F winPCAAnalyzer
	if(V_flag)
		return 0
	endif
	PauseUpdate; Silent 1		// building window...
	
	//___________
	// Host Panel
	//___________
	Newpanel /K=1 /W=(500,45,900,300) as "PCA Analyzer"
	RenameWindow $S_name, winPCAAnalyzer
	SetDrawEnv fstyle= 1, fsize= 16
	DrawText 18,20,"PCA config"
	
	//____________
	// Tab control
	//____________
	TabControl PCAmode pos={10,20},size={150,20},tabLabel(0)="2D wave",tabLabel(1)="4D wave",proc=PCAmodeTabProc
	
	//_______________
	// Analysis group
	//_______________
	GroupBox PCAConfigGroup,pos={6,40},size={389,73}
	GroupBox PCAConfigGroup font="Arial",fSize=12
	TitleBox AnalayzedWName pos={130,3},frame=0,title="Analyzed:" + G_AnalyzedPCAWaveName
	TitleBox AnalayzedWName font="Arial",fSize=12
	PopupMenu Trgt2dWList pos={30,45},size={154,30},title="Wave:",bodyWidth=120,value=#"Wavelist(\"*\",\";\",\"DIMS:2\")",proc=PCAWaveSelectPopMenuProc
	PopupMenu Trgt2dWList font="Arial",fSize=12
	PopupMenu MaskWList pos={64,66},size={120,30},title="",bodyWidth=120,value=#"Wavelist(\"*\",\";\",\"DIMS:1\")",disable=2-G_isMaskValid*2,proc=PCAMaskSelectPopMenuProc
	PopupMenu MaskWList font="Arial",fSize=12
	CheckBox CheckApplyMask pos={14,68},title="Mask",value=G_isMaskValid,proc=PCAMaskCheckProc
	CheckBox CheckApplyMask font="Arial",fSize=12
	Button DoPCA pos={300,87},title="Do Analysis",size={80,20},proc=PCAAnalysisButtonProc
	Button DoPCA font="Arial",fSize=12, fColor=(2,39321,1)
	CheckBox CheckCentering pos={205,45},title="Centering",value=G_isCenteringValid,proc=PCACenteringCheckProc
	CheckBox CheckCentering font="Arial",fSize=12
	CheckBox CheckScaling pos={205,66},title="Scaling",value=G_isScalingValid,proc=PCAScalingCheckProc
	CheckBox CheckScaling font="Arial",fSize=12
	PopupMenu Scalingmthd pos={273,64},size={110,30},bodyWidth=113,value="Whole point;Each point",proc=PCAScalingMethodPopMenuProc
	PopupMenu Scalingmthd font="Arial",fSize=12
	
	//_______________
	// result group
	//_______________
	GroupBox PCAresultGroup,pos={6,110},size={389,130},title="Result"
	GroupBox PCAresultGroup font="Arial",fSize=12
	SetVariable SCRvar0 pos={15,130},title="SCORE: PC",size={120,16},value=G_SCOREnum_x,limits={1,inf,1}
	SetVariable SCRvar0 font="Arial",fSize=12
	SetVariable SCRvar1 pos={140,130},title="vs  PC",size={85,16},value=G_SCOREnum_y,limits={1,inf,1}
	SetVariable SCRvar1 font="Arial",fSize=12
	Button ShowSCR pos={260,139},title="Show SCORE Plot",size={120,20},disable=G_is3dplotValid,proc=PCAShowSCOREButtonProc
	Button ShowSCR font="Arial",fSize=12
	CheckBox Check3dPlt pos={15,150},title="enable 3D Plot",value=G_is3dplotValid,proc=PCA3DPlotCheckProc
	CheckBox Check3dPlt font="Arial",fSize=12
	SetVariable SCRvar2 pos={140,150},title="vs  PC",size={85,16},value=G_SCOREnum_z,limits={1,inf,1},disable=2-G_is3dplotValid*2
	SetVariable SCRvar2 font="Arial",fSize=12
	SetVariable LDGvarLimit pos={15,210},title="LOADING: PC1 ~ PC",size={170,16},value=G_LOADINGregionnum,limits={1,inf,1}
	SetVariable LDGvarLimit font="Arial",fSize=12
	Button ShowLDG pos={260,210},title="Show LOADING",size={120,20},proc=PCAShowLOADINGButtonProc
	Button ShowLDG font="Arial",fSize=12
	Button Show3dPlt pos={260,139},title="Show 3D Plot",size={120,20},disable=1-G_is3dplotValid,proc=PCAShow3DSCOREButtonProc
	Button Show3dPlt font="Arial",fSize=12
	Button ShowMSCR pos={260,175},title="Show Multi SCORE",size={120,20},proc=PCAShowMSCOREButtonProc
	Button ShowMSCR font="Arial",fSize=12
	SetVariable setvar4 pos={140,177},title="To PC",size={85,16},value=G_MSCOREnum,limits={2,inf,1}
	SetVariable setvar4 font="Arial",fSize=12
	//Button SavePCArslt pos={260,245},title="Save PCA result",size={120,20},disable=2  //developing
	//Button SavePCArslt font="Arial",fSize=12	//developing
	//Button ShowBiPlt title="Show Biplot"	//developing
	
	//____________
	//Tab2: PCA_4D
	//____________
	PopupMenu Trgt4dWList pos={30,45},size={154,30},title="wave:",bodyWidth=120,disable=1,value=#"Wavelist(\"*\",\";\",\"DIMS:4\")",proc=WaveSelectPopMenuProc
	PopupMenu Trgt4dWList font="Arial",fSize=12

End

//_____________________________
// *** - Analysis ***
//_____________________________
Function PCAAnalysis()
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	DFREF dfr_saved = GetDataFolderDFR() //Saving Current DataFolder address.
	NVAR G_isCenteringValid= dfr_PCA: G_isCenteringValid
	NVAR G_isScalingValid= dfr_PCA: G_isScalingValid
	NVAR G_isMaskValid= dfr_PCA: G_isMaskValid
	NVAR G_ScalingMethod= dfr_PCA: G_ScalingMethod
	NVAR G_DataLayernum= dfr_PCA:G_DataLayernum
	SVAR G_PCAWaveName = dfr_PCA: G_PCAWaveName
	SVAR G_MaskWaveName = dfr_PCA: G_MaskWaveName
	SVAR G_AnalyzedPCAWaveName = dfr_PCA: G_AnalyzedPCAWaveName
	
	wave input_wave = $G_PCAWaveName
	wave maskwave = $G_MaskWaveName
	
	
	variable samplenum,Sp
	
	if(wavedims(input_wave)==4)					//4D wave
		variable row = Dimsize(input_wave,0)
		variable col = Dimsize(input_wave,1)
		variable Datanum = Dimsize(input_wave,2)
		G_DataLayernum = Datanum 	//using in SCORE
		Sp = Dimsize(input_wave,3)
		samplenum = row*col*Datanum
		setdataFolder RHYME_PATH + PCA_PATH
		make/O/N=(row*col*Datanum,Sp)/D temp1
		temp1 = input_wave
	else										// 2D wave
		samplenum = Dimsize(input_wave,0)
		Sp = Dimsize(input_wave,1)
		G_DataLayernum = 1
		setdataFolder RHYME_PATH + PCA_PATH
		duplicate/O input_wave temp1	
	endif
	
	variable i	
	
	
	if(G_isMaskValid==1)	//Apply mask 
		variable m
		for(m=0;m<Sp;m+=1)
			if(maskwave[m]==0)
			temp1[][m] =0
			endif
		endfor	
	endif
	
	
	if(G_isCenteringValid==1)	//Centering
		wavestats/PCST/CCL temp1
		wave M_wavestats = dfr_PCA:M_wavestats
		for(i=0;i<Sp;i+=1)
			temp1[][i] -= M_wavestats[3][i]
		endfor
		killwaves dfr_PCA:M_wavestats
		duplicate/O temp1 temp2 //
	endif
	
	
	if(G_isScalingValid==1)
		if(G_ScalingMethod==0)	//Scaling
			
			matrixtranspose temp1 	//Transpose for WaveStats
			wavestats/PCST/CCL temp1
			wave M_wavestats = dfr_PCA:M_wavestats
			for(i=0;i<samplenum;i+=1)
			temp1[][i] /= M_wavestats[4][i]		
			endfor
			matrixtranspose temp1 //Transpose for WaveStats
			killwaves dfr_PCA:M_wavestats
			duplicate/O temp1 temp3 //
		else
			wavestats/PCST/CCL temp1
			wave M_wavestats = dfr_PCA:M_wavestats
			for(i=0;i<Sp;i+=1)
				temp1[][i] /= M_wavestats[4][i]	
			endfor
			killwaves dfr_PCA:M_wavestats
		endif	
	endif	
		
	PCA/O/SEVC/RSD/SRMT/ALL/SDM/SCMT temp1
	
	G_AnalyzedPCAWaveName = G_PCAWaveName + " "
	if(G_isCenteringValid==1)
	G_AnalyzedPCAWaveName += "\f03#C"
	endif
	if(G_isScalingValid==1)
	G_AnalyzedPCAWaveName += "\f03#S"
	endif
	
	TitleBox AnalayzedWName title="Analyzed:" + G_AnalyzedPCAWaveName 
	
	setdatafolder dfr_saved
	
	if(wavedims(input_wave)==4)	//make PCA image if input was 4D
		make/O/N=(row,col,Datanum,Sp) PCAimg_4D
		wave PCAimg_2D = dfr_PCA:M_R
		PCAimg_4D = PCAimg_2D
	endif
	
	Doalert 0, "Finished!"
end

//_____________________________
// *** - Show Results ***
//_____________________________

function ShowSCOREPlot()
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_SCOREnum_x = dfr_PCA: G_SCOREnum_x
	NVAR G_SCOREnum_y = dfr_PCA: G_SCOREnum_y
	NVAR G_SCOREnum_z = dfr_PCA: G_SCOREnum_z
	NVAR G_DataLayernum= dfr_PCA:G_DataLayernum
		if(waveexists(dfr_PCA: M_R))
			wave SCORE_wave = dfr_PCA: M_R
		else
			Doalert 0,"SCORE wave does not exist."
			return 0
		endif
		
	variable Datanum_onelayer = Dimsize(SCORE_wave,0) / G_DataLayernum	
	
	//Show SCORE plot (2D)
	display SCORE_wave[][G_SCOREnum_y-1] vs SCORE_wave[][G_SCOREnum_x-1]
	ModifyGraph width=340.157,height={Aspect,1}
	ModifyGraph mode=2,lsize=3
	ModifyGraph fSize=16
	//ModifyGraph margin(right)=99
	ModifyGraph lblMargin(left)=12;DelayUpdate
	ModifyGraph zero=4
	Label left ("PC"+num2str(G_SCOREnum_y))";DelayUpdate
	Label bottom ("PC"+num2str(G_SCOREnum_x))
	
	//colorchange
	ModifyGraph rgb=(0,43690,65535)
	
	//developing: colorchange
	//if(waveexists(dfr_PCA: M_colors))
	//	WAVE M_colors = dfr_PCA: M_colors
	//else
	//	colorTab2Wave Classification
	//	WAVE M_colors
	//	movewave :M_colors,dfr_PCA
	//endif	
	//Variable ColorNum = DimSize(M_colors,0)
	//Variable ColorWaveRow = 0
	//Variable Red = M_colors[ColorWaveRow][0]
	//Variable Green = M_colors[ColorWaveRow][1]
	//Variable Blue = M_colors[ColorWaveRow][2]
	//variable i,j
	//ModifyGraph rgb(M_R)=(Red,Green,Blue) //zero
	//for(i=1;i<=G_DataLayernum;i+=1)
	//	for(j=0;j<Datanum_onelayer;j+=1)
	//		ModifyGraph rgb(M_R[j+Datanum_onelayer*(i-1)])=(Red,Green,Blue)
	//		ModifyGraph marker(M_R[j+Datanum_onelayer*(i-1)])=i*8
	//	endfor	
	//	ColorWaveRow = floor((i/G_DataLayernum) * ColorNum)-1
	//	Red = M_colors[ColorWaveRow][0]
	//	Green = M_colors[ColorWaveRow][1]
	//	Blue = M_colors[ColorWaveRow][2]
	//endfor
	
	//developing: add legend
	//string Lgdstr=""
	//variable l
	//for(l=0;l<G_DataLayernum;l+=1)
	//	Lgdstr += "\\s(M_R[" + num2str(Datanum_onelayer*l) +"]) Layer_"+num2str(l)+"\r"
	//endfor
	//Lgdstr = RemoveEnding(Lgdstr)
	//Legend/C/N=traceColor/J/E=2/A=RT/F=2 Lgdstr
End

function Show3DSCOREPlot() 
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_SCOREnum_x = dfr_PCA: G_SCOREnum_x
	NVAR G_SCOREnum_y = dfr_PCA: G_SCOREnum_y
	NVAR G_SCOREnum_z = dfr_PCA: G_SCOREnum_z
	if(waveexists(dfr_PCA: M_R))
		wave SCORE_wave = dfr_PCA: M_R
	else
		Doalert 0,"SCORE wave does not exist."
		return 0
	endif
	setdataFolder RHYME_PATH + PCA_PATH
	make/O/N=(dimsize(Score_wave,0),3) temp_3D
	temp_3D[][0] = score_wave[p][G_SCOREnum_x-1]
	temp_3D[][1] = score_wave[p][G_SCOREnum_y-1]
	temp_3D[][2] = score_wave[p][G_SCOREnum_z-1]
	NewGizmo;DelayUpdate
	AppendToGizmo DefaultScatter= temp_3D
	ModifyGizmo ModifyObject=scatter0,objectType=scatter,property={ size,0.3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,visible,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 7,visible,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 10,visible,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,lineWidth,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,lineWidth,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,lineWidth,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,ticks,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,ticks,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,ticks,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,ticks,3}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 1,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 3,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 8,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 9,axisColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelText,"PC"+num2str(G_SCOREnum_z)}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelText,"PC"+num2str(G_SCOREnum_y)}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelText,"PC"+num2str(G_SCOREnum_x)}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={5,axisLabelCenter,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={6,axisLabelCenter,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={11,axisLabelCenter,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelDistance,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelDistance,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelDistance,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelScale,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelScale,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelScale,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelRGBA,0.000000,0.000000,0.000000,1.000000}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelTilt,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelTilt,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelTilt,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={5,axisLabelFont,"default"}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={6,axisLabelFont,"default"}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={11,axisLabelFont,"default"}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,axisLabelFlip,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,axisLabelFlip,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,axisLabelFlip,0}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 5,labelBillboarding,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 6,labelBillboarding,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 11,labelBillboarding,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,gridType,42}
	
	//Draw gridline at planes
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,gridLinesColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,gridPrimaryCount,5}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 0,gridSecondaryCount,5}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,gridType,42}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,gridLinesColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,gridPrimaryCount,5}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 2,gridSecondaryCount,5}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,gridType,42}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,gridLinesColor,0.733333,0.733333,0.733333,1}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,gridPrimaryCount,5}
	ModifyGizmo ModifyObject=axes0,objectType=Axes,property={ 4,gridSecondaryCount,5}
	//ModifyGizmo appendRotation={q0,q1,q2,q3}
	ModifyGizmo resumeUpdates
	setdatafolder root:
end

function ShowMultiSCORE() : Panel
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_MSCOREnum = dfr_PCA: G_MSCOREnum
	if(waveexists(dfr_PCA: M_R))
		wave SCORE_wave = dfr_PCA: M_R
	else
		Doalert 0,"SCORE wave does not exist."
		return 0
	endif
	
	variable i,j
	display/K=1/W=(0,0,800,800) as "SCORE MATRIX"
	ModifyGraph width={Aspect,1}
	for(i=0;i<G_MSCOREnum;i+=1)
		for(j=0;j<G_MSCOREnum;j+=1)
			//Display score plot
			Display/W=((750/G_MSCOREnum)*j,(750/G_MSCOREnum)*i,(750/G_MSCOREnum)*(j+1),(750/G_MSCOREnum)*(i+1))/HOST=# SCORE_wave[][i] vs SCORE_wave[][j]
			ModifyGraph width={Aspect,1}
			ModifyGraph mode=2,lsize=3
			ModifyGraph fSize=12
			ModifyGraph lblMargin(left)=12
			ModifyGraph zero=4
			
			//Labeling Axis
			if(j==0)
				Label left ("\f01PC"+num2str(i+1))";DelayUpdate
			endif
			if(i==G_MSCOREnum-1)
				Label bottom ("\f01PC"+num2str(j+1))
			endif
			
			//colorchange_score_3() //developing: if you want, insert color change function
			
			RenameWindow #,$("G" + num2str(j) + num2str(i))
			SetActiveSubwindow ##
		endfor
	endfor
	
End


function ShowLOADING()
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	DFREF dfr_params = $(RHYME_PATH + PARAMS_PATH)
	
	NVAR G_LOADINGregionnum= dfr_PCA: G_LOADINGregionnum
	
	if(DatafolderExists(RHYME_PATH + PARAMS_PATH))	//Check Datafolder containing RamanShift existence.
		 SVAR G_XaxisWName = dfr_params:G_XaxisWName 
		 wave xaxis= $G_XaxisWName 
	endif
	
	if(Waveexists(dfr_PCA: M_C))	//Check LOADING Result existence.
		wave LOADING_wave = dfr_PCA: M_C
		wave W_CumulativeVAR = dfr_PCA: W_CumulativeVAR 
	else
		Doalert 0,"LOADING wave does not exist."
		return 0
	endif
	
	variable i
	display/W=(1630,5,2180,1255) as "LOADING"
	variable ccr = W_CumulativeVAR[0]
		for(i=0;i<G_LOADINGregionnum;i+=1)
		string axisName = "Axis" + num2str(i+1)	
		
		if(DatafolderExists(RHYME_PATH + PARAMS_PATH) && cmpstr(G_XaxisWName,"_calculated")!=0)
			AppendtoGraph/L=$axisName LOADING_wave[i][] vs xaxis
			Label bottom "Raman shift / cm\\S−1"
		else
			AppendtoGraph/L=$axisName LOADING_wave[i][]
			Label bottom "Points"
		endif
			
		SetAxis/A=2 $axisName
		ModifyGraph nticks($axisName) = 0 
		ModifyGraph lblMargin($axisName)=3
		ModifyGraph lblPosMode($axisName)=1
		ModifyGraph freePos($axisName)=0
		ModifyGraph fSize($axisName)=20	
		ModifyGraph axisEnab($axisName)={(1/G_LOADINGregionnum)*(G_LOADINGregionnum-(i+1)),(1/G_LOADINGregionnum)*(G_LOADINGregionnum-(i+1))+(0.8/G_LOADINGregionnum)}	//縦軸の占める位置(長さ)の調節
		ModifyGraph zero($axisName)=3,zeroThick($axisName)=2 //Zero line
		Label $axisName "PC" + num2str(i+1)+"\r\\Z16" + num2str(round(ccr*100)/100) + " %" 
		
		ccr = W_CumulativeVAR[i+1] - W_CumulativeVAR[i]	// calculate explained variance
		endfor
		SetAxis/A/R bottom
		ModifyGraph margin(left)=42
End


//_____________________________
// *** - Controls ***
//_____________________________

Function PCAMaskCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_isMaskValid= dfr_PCA: G_isMaskValid
	switch( cba.eventCode )
		case 2: // mouse up
			G_isMaskValid = cba.checked
			PopupMenu MaskWList disable=2-G_isMaskValid*2
			break

	endswitch

	return 0
End

Function PCACenteringCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_isCenteringValid= dfr_PCA: G_isCenteringValid
	NVAR G_isScalingValid= dfr_PCA: G_isScalingValid
	switch( cba.eventCode )
		case 2: // mouse up
			G_isCenteringValid = cba.checked
			break

	endswitch

	return 0
End

Function PCAScalingCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_isScalingValid= dfr_PCA: G_isScalingValid
	switch( cba.eventCode )
		case 2: // mouse up
			G_isScalingValid = cba.checked
			PopupMenu Scalingmthd disable=2-G_isScalingValid*2
			break

	endswitch

	return 0
End

Function PCA3DPlotCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_is3dplotValid= dfr_PCA: G_is3dplotValid
	switch( cba.eventCode )
		case 2: // mouse up
			G_is3dplotValid = cba.checked
			SetVariable SCRvar2 disable=2-G_is3dplotValid*2
			Button ShowSCR disable= cba.checked
			Button Show3dPlt disable= 1-cba.checked
			break

	endswitch

	return 0
End



Function PCAWaveSelectPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	SVAR G_PCAWaveName = dfr_PCA: G_PCAWaveName
	
	switch( pa.eventCode )
		case 2: // mouse up
			G_PCAWaveName= pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAMaskSelectPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	SVAR G_MaskWaveName = dfr_PCA: G_MaskWaveName
	
	switch( pa.eventCode )
		case 2: // mouse up
			G_MaskWaveName= pa.popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAScalingMethodPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	NVAR G_ScalingMethod= dfr_PCA: G_ScalingMethod
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			G_ScalingMethod = popNum - 1
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAAnalysisButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	SVAR G_PCAWaveName = dfr_PCA: G_PCAWaveName
	wave input_wave = $G_PCAWaveName
	
	switch( ba.eventCode )
		case 2: // mouse up
			PCAAnalysis()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAShowSCOREButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			showSCOREPlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAShow3DSCOREButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			show3DSCOREPlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAShowMSCOREButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			showMultiSCORE()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PCAShowLOADINGButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			showLOADING()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function PCAModeTabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca
	DFREF dfr_PCA = $(RHYME_PATH + PCA_PATH)
	SVAR G_PCAWaveName = dfr_PCA: G_PCAWaveName
	switch( tca.eventCode )
		case 2: // mouse up
			Variable tab = tca.tab
				PopupMenu Trgt2dWList,disable=(tca.tab!=0)
				PopupMenu Trgt4dWList,disable=(tab!=1)
				G_PCAWaveName = stringFromList(0,Wavelist("*",";","DIMS:"+num2str((tab+1)*2)))
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



