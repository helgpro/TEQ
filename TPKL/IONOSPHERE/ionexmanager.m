% IONEX DATA import/management/export script.
% Written by Tibor Durgonics

clear all; close all;

%--------------------------------------------------------------------------
% IONEXFile = 'RIM130010.INX'; % Name of the Greenlandic IONEX file.
%--------------------------------------------------------------------------
IONEXFile = 'CODG0010.13I'; % Name of the Global IONEX file.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Manually defining extent of the TEC map for Greenland.
% W = 65; 
% H = 31;
% m = 0;
%--------------------------------------------------------------------------
% Manually defining extent of the TEC map for global view.
W = 72; 
H = 70;
m = 0;
%--------------------------------------------------------------------------

% Number of lines in the IONEX file.
ShortIONEXFile = strrep(IONEXFile, '.INX', '');
NoL = CalcNumOfLines (IONEXFile);

% Number of lines in the IONEX file header.
NoHL = CalcNumOfHeaderLines (IONEXFile);

% Reading data from the IONEX header.
[EPOCH_OF_FIRST_MAP EPOCH_OF_LAST_MAP INTERVAL N_OF_MAPS_IN_FILE...
    MAPPING_FUNCTION ELEVATION_CUTOFF N_OF_STATIONS N_OF_SATELLITES...
    BASE_RADIUS MAP_DIMENSION HGT1_2_D LAT1_2_D LON1_2_D EXPONENT]...
    = ReadingHeader(IONEXFile);

N_OF_MAPS_IN_FILE = N_OF_MAPS_IN_FILE - 1; % Ignore the last map/snapshot.

DataPerBlock = W+1;
BlockPerEpoch = H+1;
LinesPerBlock = DataPerBlock/16;
FullLinesPerBlock = fix(LinesPerBlock);
DataInBlockLastLine = DataPerBlock-(FullLinesPerBlock*16);
DataFile = fopen(IONEXFile,'r');
DataPerEpoch = DataPerBlock*BlockPerEpoch;
LineTECPerBlock = zeros(BlockPerEpoch, DataPerBlock);
CSVMatrix = zeros(DataPerEpoch,3);

fseek(DataFile, 0, 'bof');
tline = fgetl(DataFile); 
for i = 1:NoHL
    tline = fgetl(DataFile); 
end

EPOCH_OF_CURRENT_MAP = zeros(N_OF_MAPS_IN_FILE,6);
LAT_LON1_LON2_DLON_H = zeros((BlockPerEpoch*N_OF_MAPS_IN_FILE),5);
XColumn = zeros(DataPerEpoch,1);
YColumn = zeros(DataPerEpoch,1);
Multiplier = 10^(EXPONENT);
TECMatrixDay = zeros(BlockPerEpoch, DataPerBlock, N_OF_MAPS_IN_FILE);
InterpTECMatrix = zeros(BlockPerEpoch*10, DataPerBlock*10, N_OF_MAPS_IN_FILE);

for j = 1:N_OF_MAPS_IN_FILE; % Actual EPOCH.

    tline = fgetl(DataFile); % EPOCH OF CURRENT MAP - This reads the first EPOCH data.
    k = strfind(tline, 'EPOCH OF CURRENT MAP');
    if ~(isempty(k)), 
        EPOCH_OF_CURRENT_MAP (j,:) = sscanf (tline, '%d %d %d %d %d %d %*s');
    end
    
    for ActualBlock = 1:BlockPerEpoch

        tline = fgetl(DataFile); % LAT/LON1/LON2/DLON/H
        k = strfind(tline, 'LAT/LON1/LON2/DLON/H');
        if ~(isempty(k)), 
            LAT_LON1_LON2_DLON_H (ActualBlock,:) = sscanf (tline, '%f %f %f %f %f %*s');
        end
        for i = 1:FullLinesPerBlock % Extracting data from full lines.
            tline = fgetl(DataFile); 
            s = sscanf (tline, '%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d');
            LineTECPerBlock (ActualBlock,((i*16)-15):(i*16))= s;
        end
        if DataInBlockLastLine ~=0 % Only if there is a last line with less than 16 data.
            tline = fgetl(DataFile); % Last line of block with less than 16 data.
            c = 's = sscanf (tline, ''';
            for l = 1:DataInBlockLastLine-1 % Extracting data from the last (not full) line.
               c = [c '%d '];
            end
            c = [c '%d'' ']; c = [c ');'];
            eval(c)
            LineTECPerBlock (ActualBlock,((i*16+1):(i*16+DataInBlockLastLine)))= s;
        end
        
    end

    tline = fgetl(DataFile); % END OF TEC MAP
    % End of an EPOCH.
    
    m = 0;
    for l = 1:BlockPerEpoch
        for i = 1:DataPerBlock
            m=m+1;
            XColumn(m,1) = LAT_LON1_LON2_DLON_H (1,2)+(i-1)*LAT_LON1_LON2_DLON_H(1,4)-1+LON1_2_D (3,1); 
            YColumn(m,1) = LAT_LON1_LON2_DLON_H (l,1); 
        end
    end

    tline = fgetl(DataFile); % START OF TEC MAP
    [maxNumCol, maxIndexCol] = max(LineTECPerBlock); %Filtering
    [maxNum, col] = max(maxNumCol);
    row = maxIndexCol(col);
    if LineTECPerBlock(row, col) > 998;
       LineTECPerBlock(row, col) = LineTECPerBlock(row, col-1); 
    end    
    MLineTECPerBlock = LineTECPerBlock .* Multiplier;
    TECMatrixDay (:,:,j) = flipud(MLineTECPerBlock);
    
end

fclose ('all');
