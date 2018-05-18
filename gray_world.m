%% gray world algorithm
% A Rostov 16/05/2018
% a.rostov@riftek.com
%%

fileID = -1;
errmsg = '';
while fileID < 0 
   disp(errmsg);
   filename = input('Open file: ', 's');
   [fileID,errmsg] = fopen(filename);
   I = imread(filename);
end
[Nx, Ny, Nz] = size(I);

display('Writing data for RTL model...');
fidR = fopen('Rdata.txt', 'w');
fidG = fopen('Gdata.txt', 'w');
fidB = fopen('Bdata.txt', 'w');

zerI = zeros(Nx, Ny, Nz);

Iwr = cat(1, I, zerI, I, zerI);

for i = 1 : 4*Nx
    for j = 1 : Ny
      fprintf(fidR, '%x\n', Iwr(i, j, 1));
      fprintf(fidG, '%x\n', Iwr(i, j, 2));
      fprintf(fidB, '%x\n', Iwr(i, j, 3));
    end
end
fclose(fidR);
fclose(fidG);
fclose(fidB);

%%
fid = fopen('parameters.vh', 'w');
fprintf(fid,'parameter Nrows   = %d ;\n', Ny);
fprintf(fid,'parameter Ncol    = %d ;\n', Nx);
fclose(fid);

%%
display('Please, start write_prj.tcl');
prompt = 'Press Enter when RTL modeling is done \n';
x = input(prompt);


I_data = zeros(Nx, Ny, Nz);
I_data = double(I);
 R_sum = 0;
 G_sum = 0;
 B_sum = 0;

for i = 1 : Nx
    for j = 1 : Ny 
       R_sum = R_sum + I_data(i, j, 1); 
       G_sum = G_sum + I_data(i, j, 2); 
       B_sum = B_sum + I_data(i, j, 3); 
    end
end

mult = Nx*Ny
mult_log2 = floor(log2(Nx*Ny))

deltaLOG2 = mult - 2^mult_log2
N = 2^mult_log2

R_sumR = floor(R_sum/(mult))
G_sumR = G_sum/(mult);
B_sumR = B_sum/(mult);

Arg     = (R_sumR + G_sumR + B_sumR)/3;


for i = 1 : Nx
    for j = 1 : Ny 
       I_data(i, j, 1) = floor(I_data(i, j, 1) * Arg / R_sumR); 
       I_data(i, j, 2) = floor(I_data(i, j, 2) * Arg / G_sumR); 
       I_data(i, j, 3) = floor(I_data(i, j, 3) * Arg / B_sumR); 
    end
end

 I_data     = uint8(I_data);

% read processing data
 fidR = fopen(fullfile([pwd '\gray_world.sim\sim_1\behav\xsim'],'Rs_out.txt'), 'r');
 fidG = fopen(fullfile([pwd '\gray_world.sim\sim_1\behav\xsim'],'Gs_out.txt'), 'r');
 fidB = fopen(fullfile([pwd '\gray_world.sim\sim_1\behav\xsim'],'Bs_out.txt'), 'r');


R = zeros(1, Nx*Ny);
G = zeros(1, Nx*Ny);
B = zeros(1, Nx*Ny);
  R = fscanf(fidR,'%d');  
  G = fscanf(fidG,'%d');  
  B = fscanf(fidB,'%d');  
fclose(fidR);
fclose(fidG);
fclose(fidB);

Iprocess = zeros(Nx, Ny, 3);
n = 1;
for i = 1 : Nx - 1;
    for j = 1 : Ny 
       Iprocess(i, j, 1) = R(n + 0*201851); 
       Iprocess(i, j, 2) = G(n + 0*201851); 
       Iprocess(i, j, 3) = B(n + 0*201851); 
       n = n + 1;
 end
end
Iprocess = uint8(Iprocess);


figure(1)
imshow(I);
title('before processing')


figure(2)
imshow(I_data);
title('after processing Matlab')

figure(3)
imshow(Iprocess);
title('after processing HDL')


