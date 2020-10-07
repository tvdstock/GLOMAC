clear
close all

%%
%settings, modify as needed

intLevel = 1; %k level

%set to a nonzero value to plot budget terms
plotVolumeBudget = 0;
plotSalinityBudget = 1;
plotDICBudget = 0;

%set to a nonzero value to save as jpg files
printBudget = 0;

gridDir = '../../../../darwin3/run/';
modelDir = '../../../../darwin3/run/';

%%
%plotting params.

fs = 12;
lw = 2;

colors = parula(500);

%%
%constants

secPerDay = 86400;
secPerHour = 3600;
hoursPerDay = 24;
deltaT = 3600;

rhoConst = 1029;
mmol_to_mol = 1 ./ 1000;

%%
%load grid

nx = 128;
ny = 64;
nz = 15;

XC = readbin([modelDir 'XC.data'],[nx ny],1,'real*8');
YC = readbin([modelDir 'YC.data'],[nx ny],1,'real*8');
hFacC = readbin([modelDir 'hFacC.data'],[nx ny nz],1,'real*8');
RAC = readbin([modelDir 'RAC.data'],[nx ny],1,'real*8');
DXG = readbin([modelDir 'DXG.data'],[nx ny],1,'real*8');
DYG = readbin([modelDir 'DYG.data'],[nx ny],1,'real*8');
DRF = readbin([modelDir 'dRF.data'],[nz],1,'real*8');
RC = readbin([modelDir 'RC.data'],[nz],1,'real*8');

numLevels = numel(RC);

depth = readbin([modelDir 'Depth.data'],[nx ny],1,'real*8');

dzMatF = repmat(DRF,1,nx,ny);
dzMatF = permute(dzMatF,[2 3 1]);
dzMat = dzMatF .* hFacC;

RACMat = repmat(RAC,1,1,nz);

mskC = hFacC .* 1;
mskC(hFacC == 0) = nan;
mskC(~isnan(mskC)) = 1;

VVV = mskC .* hFacC .* RACMat .* dzMatF;

%%

diagDir = [modelDir 'diags/budget/'];

filename1 = 'average_2d';
filename2 = 'average_velmass_3d';
filename3 = 'average_salt_3d';
filename4 = 'average_dic_3d';
filename5 = 'snap_2d';
filename6 = 'snap_3d';

%%

fn = dir([diagDir filename1 '.*.data']);
tt = zeros(length(fn),1);

for i = 1:length(tt)
    
    nme = fn(i).name;
    tt(i) = str2num(nme(end-14:end-5));
    
end

numFiles = numel(tt);
dt = diff([0 tt']);
dt = dt ./ (secPerDay ./ deltaT) .* hoursPerDay; %hours

numTimeSteps = numel(tt);

%%

if printBudget
    figDir='../figures';
    if ~exist(figDir), eval(['mkdir ' figDir]), end
    if plotVolumeBudget
        if ~exist([figDir '/VolumeBudget'])
            eval(['mkdir ' figDir '/VolumeBudget'])
    end,end
    if plotSalinityBudget
        if ~exist([figDir '/SalinityBudget'])
            eval(['mkdir ' figDir '/SalinityBudget'])
    end,end
    if plotDICBudget
        if ~exist([figDir '/DICBudget'])
            eval(['mkdir ' figDir '/DICBudget'])
end,end,end

%%

for timeStep = 1:numFiles
    
    disp(num2str(timeStep));
    
    %set file numbers to load in
    if timeStep ==1
        
        ttAverage = tt(timeStep);
        ttSnap = [1 tt(timeStep)];
        
    else %timeStep~=1
        
        ttAverage = tt(timeStep);
        ttSnap = [tt(timeStep-1) tt(timeStep)];
        
    end
        %load two-dimensional time-averaged fields
    ETAN = rdmds([diagDir filename1],ttAverage,'rec',1);    
    oceFWflx = rdmds([diagDir filename1],ttAverage,'rec',2);
    SFLUX = rdmds([diagDir filename1],ttAverage,'rec',3);
    oceSPflx = rdmds([diagDir filename1],ttAverage,'rec',4);
    DICTFLX = rdmds([diagDir filename1],ttAverage,'rec',5) .* mmol_to_mol; %mol m^-3 s^-1

    %load three-dimensional time-averaged fields
    UVELMASS = rdmds([diagDir filename2],ttAverage,'rec',1);
    VVELMASS = rdmds([diagDir filename2],ttAverage,'rec',2);
    WVELMASS = rdmds([diagDir filename2],ttAverage,'rec',3);
    
    SALT = rdmds([diagDir filename3],ttAverage,'rec',1);
    ADVx_SLT = rdmds([diagDir filename3],ttAverage,'rec',2);
    ADVy_SLT = rdmds([diagDir filename3],ttAverage,'rec',3);
    ADVr_SLT = rdmds([diagDir filename3],ttAverage,'rec',4);
    DFxE_SLT = rdmds([diagDir filename3],ttAverage,'rec',5);
    DFyE_SLT = rdmds([diagDir filename3],ttAverage,'rec',6);
    DFrE_SLT = rdmds([diagDir filename3],ttAverage,'rec',7);
    DFrI_SLT = rdmds([diagDir filename3],ttAverage,'rec',8);
    oceSPtnd = rdmds([diagDir filename3],ttAverage,'rec',9);
    
    DIC = rdmds([diagDir filename4],ttAverage,'rec',1) .* mmol_to_mol; %mol m^-3
    ADVx_DIC = rdmds([diagDir filename4],ttAverage,'rec',2) .* mmol_to_mol; %mol s^-1
    ADVy_DIC = rdmds([diagDir filename4],ttAverage,'rec',3) .* mmol_to_mol; %mol s^-1
    ADVr_DIC = rdmds([diagDir filename4],ttAverage,'rec',4) .* mmol_to_mol; %mol s^-1
    DFxE_DIC = rdmds([diagDir filename4],ttAverage,'rec',5) .* mmol_to_mol; %mol s^-1
    DFyE_DIC = rdmds([diagDir filename4],ttAverage,'rec',6) .* mmol_to_mol; %mol s^-1
    DFrE_DIC = rdmds([diagDir filename4],ttAverage,'rec',7) .* mmol_to_mol; %mol s^-1
    DFrI_DIC = rdmds([diagDir filename4],ttAverage,'rec',8) .* mmol_to_mol; %mol s^-1
    BIO_DIC = rdmds([diagDir filename4],ttAverage,'rec',9) .* mmol_to_mol;  %mol m^-3 s^-1
    
    %%
    %load snapshots
    
    ETAN_SNAP = nan*ones(nx,ny,2);
    SALT_SNAP = nan .* ones(nx,ny,numLevels,2);
    DIC_SNAP = nan .* ones(nx,ny,numLevels,2);
    
    if timeStep == 1
        
        %no pre-initial snapshot
        ETAN_SNAP(:,:,2) = rdmds([diagDir filename5],tt(1),'rec',1);
        SALT_SNAP(:,:,:,2) = rdmds([diagDir filename6],tt(1),'rec',1);
        DIC_SNAP(:,:,:,2) = rdmds([diagDir filename6],tt(1),'rec',2) .* mmol_to_mol;  %mol m^-3 s^-1
        
    elseif timeStep == numFiles %no final snapshot
        
        ETAN_SNAP(:,:,1) = rdmds([diagDir filename5],tt(timeStep-1),'rec',1);
        SALT_SNAP(:,:,:,1) = rdmds([diagDir filename6],tt(timeStep-1),'rec',1);
        DIC_SNAP(:,:,:,1) = rdmds([diagDir filename6],tt(timeStep-1),'rec',2) .* mmol_to_mol;  %mol m^-3 s^-1
        
    else %timeStep~=1 & timeStep~=numFiles
        
        ETAN_SNAP = rdmds([diagDir filename5],ttSnap,'rec',1);
        SALT_SNAP = rdmds([diagDir filename6],ttSnap,'rec',1);
        DIC_SNAP = rdmds([diagDir filename6],ttSnap,'rec',2) .* mmol_to_mol;  %mol m^-3 s^-1
        
    end
    
    %%
    %volume budget, s^-1
   
    %total tendency
    tendV = 1 ./ repmat(depth,1,1,numLevels) .* repmat((ETAN_SNAP(:,:,2) - ETAN_SNAP(:,:,1)) ...
        ./ ((secPerHour .* dt(timeStep))),1,1,numLevels);

    facW = repmat(DYG,1,1,numLevels);
    facS = repmat(DXG,1,1,numLevels);
    
    FLDU = UVELMASS .* facW;
    FLDV = VVELMASS .* facS;
    
    FLDU(nx+1,:,:) = FLDU(1,:,:);
    FLDV(:,ny+1,:) = FLDV(:,end,:);
    
    fldDIV = (FLDU(1:end-1,:,:) - FLDU(2:end,:,:)) + ...
              (FLDV(:,1:end-1,:) - FLDV(:,2:end,:));

    adv_hConvV = mskC .* fldDIV ./ (RACMat .* hFacC);
          
    %vertical divergence
    adv_vConvV = 0 .* adv_hConvV;
    
    for k = 1:numLevels
    
        kp1 = min([k+1,numLevels]);
        
        adv_vConvV(:,:,k) = squeeze((WVELMASS(:,:,kp1) .* double(k~=numLevels)) - (WVELMASS(:,:,k) .* double(k~=1))) ...
            ./ (dzMat(:,:,k));   
        
    end
    
    %forcing
    forcV = mskC .* repmat(oceFWflx,1,1,numLevels) ./ (dzMat .* rhoConst);   
    forcV(:,:,2:numLevels) = 0 .* mskC(:,:,2:numLevels);
    
    %%
    %salt budget, psu s^-1
    
    S_snap = 0 .* SALT_SNAP;
    
    for nt = 1:2
        
        S_snap(:,:,:,nt) = (SALT_SNAP(:,:,:,nt) .* (1+repmat(ETAN_SNAP(:,:,nt) ./ depth,1,1,numLevels)));
        
    end
    
    %tendency
    tendS = (S_snap(:,:,:,2) - S_snap(:,:,:,1)) ./ (secPerHour .* dt(timeStep));
    
    %horizontal divergences
    ADVx_SLT(nx+1,:,:) = ADVx_SLT(1,:,:);
    ADVy_SLT(:,ny+1,:) = ADVy_SLT(:,end,:);
   
    clear fldDIV
    
    fldDIV = (ADVx_SLT(1:end-1,:,:) - ADVx_SLT(2:end,:,:)) + ...
              (ADVy_SLT(:,1:end-1,:) - ADVy_SLT(:,2:end,:));

    adv_hConvS = mskC .* fldDIV ./ (VVV);
   
    DFxE_SLT(nx+1,:,:) = DFxE_SLT(1,:,:);
    DFyE_SLT(:,ny+1,:) = DFyE_SLT(:,end,:);
   
    clear fldDIV

    fldDIV = (DFxE_SLT(1:end-1,:,:) - DFxE_SLT(2:end,:,:)) + ...
              (DFyE_SLT(:,1:end-1,:) - DFyE_SLT(:,2:end,:));

    dif_hConvS = mskC .* fldDIV ./ (VVV);
    
    %vertical divergences
    adv_vConvS = 0 .* ADVx_SLT(1:nx,:,:);
    dif_vConvS = 0 .* ADVx_SLT(1:nx,:,:);
    
    for k = 1:numLevels
        
        kp1 = min([k+1,numLevels]);
        
        adv_vConvS(:,:,k) = squeeze((ADVr_SLT(:,:,kp1) .* double(k~=numLevels)) - ADVr_SLT(:,:,k));
        dif_vConvS(:,:,k) = squeeze((DFrI_SLT(:,:,kp1) .* double(k~=numLevels)) - DFrI_SLT(:,:,k) ...
            + DFrE_SLT(:,:,kp1) .* double(k~=numLevels) - DFrE_SLT(:,:,k));
        
    end
    
    adv_vConvS = adv_vConvS ./ VVV;
    dif_vConvS = dif_vConvS ./ VVV;
    
    %surface salt flux
    forcS = 0 .* oceSPtnd;
    
    for nz = 1:numLevels
        
        if nz == 1
            
            forcS(:,:,nz) = SFLUX ./ rhoConst;
            
        end
        
        forcS(:,:,nz) = forcS(:,:,nz) + (oceSPtnd(:,:,nz) ./ rhoConst);
        
    end
    
    forcS = forcS ./ dzMat;
    
    surfS = mskC(:,:,1) .* SALT(:,:,1);
    
    %%
    %salinity budget
    
    rstarfac = (depth + ETAN) ./ depth;
    
    %tendency
    tendSal = mskC .* (SALT_SNAP(:,:,:,2) - SALT_SNAP(:,:,:,1)) ...
        ./ (secPerHour .* dt(timeStep));
    
    %advection
    adv_hConvSal = (-SALT .* adv_hConvV + adv_hConvS) ./ rstarfac;
    adv_vConvSal = (-SALT .* adv_vConvV + adv_vConvS) ./ rstarfac;
    
    %diffusion
    dif_hConvSal = dif_hConvS ./ rstarfac;
    dif_vConvSal = dif_vConvS ./ rstarfac;
    
    %forcing
    forcSal = (-SALT .* forcV + forcS) ./ rstarfac;
    
    %%
    %DIC budget
    
    D_snap = 0 .* DIC_SNAP;
    
    for nt = 1:2
        
        D_snap(:,:,:,nt) = (DIC_SNAP(:,:,:,nt) .* (1+repmat(ETAN_SNAP(:,:,nt) ./ depth,1,1,numLevels)));
        
    end
    
    %tendency, mol m^-3 s^-1
    tendDIC = mskC .* (D_snap(:,:,:,2) - D_snap(:,:,:,1)) ./ (secPerHour .* dt(timeStep));
    
    %horizontal divergences
    ADVx_DIC(nx+1,:,:) = ADVx_DIC(1,:,:);
    ADVy_DIC(:,ny+1,:) = ADVy_DIC(:,end,:);
   
    clear fldDIV
    
    fldDIV = (ADVx_DIC(1:end-1,:,:) - ADVx_DIC(2:end,:,:)) + ...
              (ADVy_DIC(:,1:end-1,:) - ADVy_DIC(:,2:end,:));

    adv_hConvDIC = mskC .* fldDIV ./ (VVV); %add hFacC?
   
    DFxE_DIC(nx+1,:,:) = DFxE_DIC(1,:,:);
    DFyE_DIC(:,ny+1,:) = DFyE_DIC(:,end,:);
   
    clear fldDIV

    fldDIV = (DFxE_DIC(1:end-1,:,:) - DFxE_DIC(2:end,:,:)) + ...
              (DFyE_DIC(:,1:end-1,:) - DFyE_DIC(:,2:end,:));

    dif_hConvDIC = mskC .* fldDIV ./ (VVV); %add hFacC?
    
    %vertical divergences
    adv_vConvDIC = 0 .* ADVx_DIC(1:nx,:,:);
    dif_vConvDIC = 0 .* ADVx_DIC(1:nx,:,:);
    
    for k = 1:numLevels
        
        kp1 = min([k+1,numLevels]);
        
        adv_vConvDIC(:,:,k) = squeeze((ADVr_DIC(:,:,kp1) .* double(k~=numLevels)) - ADVr_DIC(:,:,k));
        dif_vConvDIC(:,:,k) = squeeze((DFrI_DIC(:,:,kp1) .* double(k~=numLevels)) - DFrI_DIC(:,:,k) ...
            + DFrE_DIC(:,:,kp1) .* double(k~=numLevels) - DFrE_DIC(:,:,k));
        
    end
    
    adv_vConvDIC = adv_vConvDIC ./ VVV;
    dif_vConvDIC = dif_vConvDIC ./ VVV;
    
    %air-sea CO2 flux tendency, mol m^-3 s^-1
    forcDIC = 0 .* oceSPtnd;
    
    for nz = 1:numLevels
        
        if nz == 1
            
            forcDIC(:,:,1) = DICTFLX;
            
        else
            
            forcDIC(:,:,nz) = 0;
            
        end
        
    end
    
    forcDIC = mskC .* forcDIC;
    
    BIO_DIC = BIO_DIC - forcDIC; %remove air-sea CO2 flux from gDAR
    
    %biology, mol m^-3 s^-1
    bioDIC = mskC .* BIO_DIC;
   
    surfDIC = mskC(:,:,1) .* DIC(:,:,1);
    meanSurf_DIC = nansum(surfDIC(:) .* RAC(:)) ./ nansum(RAC(:));
    
    %virtualFluxDIC = mskC .* forcSal .* (surfDIC ./ surfS);
    virtualFluxDIC = mskC .* (forcSal - forcS) .* (surfDIC ./ surfS);
    
    %z* correction, as done in salinity budget
    
    tendDICzs = mskC .* (DIC_SNAP(:,:,:,2) - DIC_SNAP(:,:,:,1)) ...
        ./ (secPerHour .* dt(timeStep));
    
    %advection
    adv_hConvDICzs = (-DIC .* adv_hConvV + adv_hConvDIC) ./ rstarfac;
    adv_vConvDICzs = (-DIC .* adv_vConvV + adv_vConvDIC) ./ rstarfac;
    
    %diffusion
    dif_vConvDICzs = dif_vConvDIC ./ rstarfac;
    dif_hConvDICzs = dif_hConvDIC ./ rstarfac;
    
    %forcing
    forcDICzs = forcDIC ./ rstarfac;
    
    %biology
    bioDICzs =  bioDIC ./ rstarfac;
    
    %virtual flux
    virtualFluxDICzs = virtualFluxDIC ./ rstarfac;
     
    %%

    intTendV = tendV(:,:,intLevel);
    intHConvV = adv_hConvV(:,:,intLevel);
    intVConvV = adv_vConvV(:,:,intLevel);
    intForcV = forcV(:,:,intLevel);
    
    intTendS = tendS(:,:,intLevel);
    intHAdvS = adv_hConvS(:,:,intLevel);
    intVAdvS = adv_vConvS(:,:,intLevel);
    intHDifS = dif_hConvS(:,:,intLevel);
    intVDifS = dif_vConvS(:,:,intLevel);
    intForcS = forcS(:,:,intLevel);
    
    intTendSal = tendSal(:,:,intLevel);
    intHAdvSal = adv_hConvSal(:,:,intLevel);
    intVAdvSal = adv_vConvSal(:,:,intLevel);
    intHDifSal = dif_hConvSal(:,:,intLevel);
    intVDifSal = dif_vConvSal(:,:,intLevel);
    intForcSal = forcSal(:,:,intLevel);
    
    intTendDIC = tendDIC(:,:,intLevel);
    intHAdvDIC = adv_hConvDIC(:,:,intLevel);
    intVAdvDIC = adv_vConvDIC(:,:,intLevel);
    intHDifDIC = dif_hConvDIC(:,:,intLevel);
    intVDifDIC = dif_vConvDIC(:,:,intLevel);
    intForcDIC = forcDIC(:,:,intLevel);
    intVirtualFluxDIC = virtualFluxDIC(:,:,intLevel);
    intBioDIC = bioDIC(:,:,intLevel);
    
    %%
    %plot budgets
    
    if plotVolumeBudget
        
        hFig1 = figure(1);
        set(hFig1,'units','normalized','outerposition',[0 0 1 1]);
        set(gcf,'color',[1 1 1]);
        set(gca,'color',[0.5 0.5 0.5]);
        
        cMin = -10^-8;
        cMax = 10^-8;
        
        subplot(161);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendV);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        ylabel('Latitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Tendency (m s^-^1), ';'Timestep: ';num2str(tt(timeStep))},'FontWeight','Bold','FontSize',fs);
        
        subplot(162);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHConvV);
        shading flat
        
        caxis([cMin .* 10^3 cMax .* 10^3]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal';'Advection (m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(163);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVConvV);
        shading flat
        
        caxis([cMin .* 10^3 cMax .* 10^3]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical';'Advection (m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(164);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intForcV);
        shading flat
        
        caxis([cMin .* 10 cMax .* 10]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Surface Volume';'Forcing (m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(165);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHConvV + intVConvV + intForcV);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Total';'Budget (m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(166);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendV - (intForcV + intHConvV + intVConvV));
        shading flat
        
        caxis([cMin .* 10^-3 cMax .* 10^-3]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title('Residual (m s^-^1)','FontWeight','Bold','FontSize',fs);
        
        drawnow
        
        if printBudget
            eval(['print -djpeg ' figDir '/VolumeBudget/frame_' myint2str(timeStep,3)])
        end
        
    end
    
    if plotSalinityBudget
        
        hFig2 = figure(2);
        set(hFig2,'units','normalized','outerposition',[0 0 1 1]);
        set(gcf,'color',[1 1 1]);
        
        cMin = -10^-7;
        cMax = 10^-7;
        
        subplot(281);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendS);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        ylabel('Latitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Salt Tendency (psu m s^-^1)';'Timestep: ';num2str(tt(timeStep))},'FontWeight','Bold','FontSize',fs);
        
        subplot(282);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHAdvS);
        shading flat
        
        caxis([cMin .* 10 cMax .* 10]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal';'Advection';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(283);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVAdvS);
        shading flat
        
        caxis([cMin .* 10 cMax .* 10]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical';'Advection';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(284);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHDifS);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal';'Diffusion';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(285);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVDifS);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical';'Diffusion';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(286);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intForcS);
        shading flat
        
        caxis([cMin .* 10^-2 cMax .* 10^-2]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Surface';'Volume';'Forcing';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(287);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHAdvS + intVAdvS + intHDifS + intVDifS + intForcS);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Budget';'Total';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(288);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendS - (intHAdvS + intVAdvS + intHDifS + intVDifS + intForcS));
        shading flat
        
        caxis([cMin .* 10^-5 cMax .* 10^-5]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Budget Total - Tend';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(289);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendSal);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        ylabel('Latitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Salinity Tendency (psu m s^-^1),';'Timestep: ';num2str(tt(timeStep))},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,10);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHAdvSal);
        shading flat
        
        caxis([cMin * 10 cMax * 10]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal';'Advection';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,11);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVAdvSal);
        shading flat
        
        caxis([cMin * 10 cMax * 10]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical';'Advection';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,12);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHDifSal);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal';'Diffusion';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,13);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVDifSal);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical';'Diffusion';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,14);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intForcSal);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Surface';'Volume';'Forcing';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,15);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,(intHAdvSal + intVAdvSal + intHDifSal + intVDifSal + intForcSal));
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Budget';'Total';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,8,16);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendSal - (intHAdvSal + intVAdvSal + intHDifSal + intVDifSal + intForcSal));
        shading flat
        
        caxis([cMin .* 10^-5 cMax .* 10^-5]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Budget Total - Tend';'(psu m s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        drawnow
                        
        if printBudget
            eval(['print -djpeg ' figDir '/SalinityBudget/frame_' myint2str(timeStep,3)])
        end

    end
    
    if plotDICBudget
        
        hFig3 = figure(3);
        set(hFig3,'units','normalized','outerposition',[0 0 1 1]);
        set(gcf,'color',[1 1 1]);
        set(gca,'color',[0.5 0.5 0.5]);
        
        cMin = -10^-6;
        cMax = 10^-6;
        
        subplot(2,5,1);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        ylabel('Latitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'DIC Tendency (mol m^-^2 s^-^1), ';'timeStep: ';num2str(tt(timeStep))},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,2);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHAdvDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal Advection';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,3);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVAdvDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical Advection';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,4);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHDifDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Horizontal Diffusion';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,5);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVDifDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Vertical Diffusion';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,6);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intForcDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        ylabel('Latitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Air-sea CO_2 Flux';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,7);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intVirtualFluxDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Freshwater Dilution';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,8);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intBioDIC);
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Biology';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,9);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intHAdvDIC + intVAdvDIC + intHDifDIC + intVDifDIC ...
            + intForcDIC + intVirtualFluxDIC + intBioDIC);
        
        shading flat
        
        caxis([cMin cMax]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Total Budget';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        subplot(2,5,10);
        
        hold on
        
        set(gca,'color',[0.5 0.5 0.5]);
        
        pcolor(XC,YC,intTendDIC - (intHAdvDIC + intVAdvDIC ...
            + intHDifDIC + intVDifDIC + intForcDIC + intVirtualFluxDIC + intBioDIC));
        
        shading flat
        caxis([cMin * 10^-2 cMax * 10^-2]);
        
        colormap(colors);
        
        colorbar
        
        axis tight
        
        xlim([0 360]);
        ylim([-90 90]);
        
        set(gca,'xtick',[0:180:360]);
        set(gca,'ytick',[-90:30:90]);
        
        xlabel('Longitude (deg)');
        
        box on
        set(gca,'LineWidth',lw);
        set(gca,'FontSize',fs);
        
        title({'Budget Total - Tend';'(mol m^-^2 s^-^1)'},'FontWeight','Bold','FontSize',fs);
        
        drawnow
                        
        if printBudget
            eval(['print -djpeg ' figDir '/DICBudget/frame_' myint2str(timeStep,3)])
        end
        
    end
   
end
