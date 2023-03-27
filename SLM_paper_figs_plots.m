close all
clear


%%
SLMm = 1152;
SLMn = 960; % half width of 1920


SLMm_mm = 10.7;
SLMn_mm = 8.8; % half width 


obj_mag = 25;
obj_NA = 1.05;
% 
% obj_mag = 20;
% obj_NA = .95;

wavelength = 940e-9;

k = 2*pi/wavelength;

obj_RI = 1.33;
f_tube = 180;  % in mm

f_obj = f_tube/obj_mag;



%% diffraction efficiency of blazed gratings vs number of levels

N = 1:100;% number of levels in blazed

nu = (sin(pi./N)./(pi./N)).^2;

figure;
subplot(1,2,1);
plot(N, nu, 'k', 'linewidth', 2); 
axis tight;
title('Blazed grating diffraction efficiency')
ylabel('diffraction efficiency');
xlabel('Number of grating levels per period');

subplot(1,2,2);
semilogx(N, nu, 'k', 'linewidth', 2); 
axis tight;
title('Blazed grating diffraction efficiency')
ylabel('diffraction efficiency');
xlabel('Number of grating levels per period');

figure;
semilogx(N, nu, 'k', 'linewidth', 2); 
axis tight;
title('Blazed grating diffraction efficiency')
ylabel('diffraction efficiency');
xlabel('Number of grating levels per period');


%%

M_phase = 56/55; % magnification of SLM phase to back of objective
M_image = 33/1400; % magnification of points image pattern from right after SLM

%SLM_pix_pitch = 9.2e-6;


SLM_pix_pitch = (5:0.2:12)*1e-6;

min_pix_num = [2, 4, 8, 16];
SLM_def_dist_all = zeros(numel(SLM_pix_pitch), numel(min_pix_num));

num_pix = numel(min_pix_num);

colors1 = parula(num_pix+1);

figure; hold on;
for n_px = 1:numel(min_pix_num)

    % period*sin(theta) = m*wavelength
    SLM_def_angle = asin(wavelength./(SLM_pix_pitch*min_pix_num(n_px)));

    f_lens = .3;

    SLM_def_dist = f_lens*tan(SLM_def_angle) * M_image;
    
    SLM_def_dist_all(:,n_px) = SLM_def_dist;
    
    plot(SLM_pix_pitch/1e-6, SLM_def_dist./1e-6, 'linewidth', 2, 'color', colors1(n_px,:));
end


xlabel('pixel pitch (um)')
ylabel('deflection dist (um)');
title('Blazed period vs deflection distance')
legend({[num2str(min_pix_num') repmat(' pix period', [4, 1])]})

%%

f_obj = f_tube/obj_mag;

diameter_bfp1 = 2 * f_obj * obj_NA/obj_RI; % assuming objectives have been optimized to follow paraxial approx

diameter_bfp2 = 2 * f_obj * tan(asin(obj_NA/obj_RI)); % more like reality


NA_effm = SLMm_mm * M_phase / diameter_bfp2; 
NA_effn = SLMn_mm * M_phase / diameter_bfp2; 

%% efficiency parameters
max_dist = 500;
NA_eff_plot = 0.1:0.1:1;

z_range = (0:10:max_dist)*1e-6;
x_range = (0:10:max_dist)*1e-6;


NA_eff_comp = 0.1:0.01:1.05;
pat_pixels = [512, 960, 1024, 1152, 1920];

eff_lim = .95;
d_z = 2e-6;
d_x = 2e-6;

%% defocus efficiency

% n*k*z*cos(theta)
% n*k*z*sqrt(1-sin(theta)^2)
% sin(theta) = rho*sin(alpha)

num_z = numel(z_range);
num_NA = numel(NA_eff_plot);

rho = linspace(0, 1, SLMm/2);
colors1 = parula(num_NA);

eff_all = zeros(num_z,num_NA);
figure; hold on;
for n_na = 1:num_NA
    sin_alpha = NA_eff_plot(n_na)/obj_RI;
    phase = obj_RI * k * sqrt(1 - rho.^2 * sin_alpha^2);
    phase = phase - min(phase);

    for n_z = 1:num_z
        %pix_levels = floor((abs(z_range(n_z)) * phase)/(2*pi));
        pix_levels = floor(floor((abs(z_range(n_z)) * phase)/(pi))/2);


        [C,level_changes, ic] = unique(pix_levels, 'last');
        level_counts = -diff([level_changes; 0]);

        level_eff = (sin(pi./level_counts)./(pi./level_counts)).^2;

        level_rad = level_changes/(SLMm/2);
        frac_areas = pi*level_rad.^2/pi;
        level_frac_areas = -diff([frac_areas; 0]);

        eff_all(n_z, n_na) = sum(level_eff.*level_frac_areas);
    end
    plot(z_range/1e-6, eff_all(:,n_na), 'color', colors1(n_na,:), 'Linewidth', 2)
end
legend(num2str(NA_eff_plot'), 'location', 'southwest')
xlabel('Defocus distance (um)')
ylabel('Diffraction efficiency')
xlim('tight')
ylim([0 1]);
title(sprintf('Defocus efficiency vs NAeff, for %d pixel SLM', SLMm))

%% max defocus dist

num_pat = numel(pat_pixels);
num_NA = numel(NA_eff_comp);

colors1 = parula(num_pat+1);

dist_all = zeros(num_NA, num_pat);
figure;  hold on
for n_pat = 1:num_pat
    rho = linspace(0, 1, pat_pixels(n_pat)/2);
    
    for n_na = 1:num_NA
        sin_alpha = NA_eff_comp(n_na)/obj_RI;
        phase = obj_RI * k * sqrt(1 - rho.^2 * sin_alpha^2);
        phase = phase - min(phase);

        temp_eff = 1;
        temp_z = 0;
        
        while temp_eff>eff_lim
            temp_z = temp_z + d_z;
            %pix_levels = floor((abs(z_range(n_z)) * phase)/(2*pi));
            pix_levels = floor(floor((temp_z * phase)/(pi))/2);

            [C,level_changes, ic] = unique(pix_levels, 'last');
            level_counts = -diff([level_changes; 0]);

            level_eff = (sin(pi./level_counts)./(pi./level_counts)).^2;

            level_rad = level_changes/(pat_pixels(n_pat)/2);
            frac_areas = pi*level_rad.^2/pi;
            level_frac_areas = -diff([frac_areas; 0]);

            temp_eff = sum(level_eff.*level_frac_areas);

        end
        dist_all(n_na, n_pat) = temp_z - d_z;
    end
    plot(dist_all(:, n_pat)/1e-6, NA_eff_comp, 'Linewidth', 2, 'color', colors1(n_pat,:));
end
legend(num2str(pat_pixels'))
xlabel(sprintf('Defocus distance (um)'))
ylabel('NAeff')
ylim([NA_eff_comp(1) NA_eff_comp(end)]);
xlim([0 max_dist])
title(sprintf('Distance at %d%% defocus efficiency vs NAeff', eff_lim*100))


%% lateral efficiency

% n*k*x*sin(theta)
% n*k*x*sin(alpha)*rho

num_x = numel(x_range);
num_NA = numel(NA_eff_plot);

rho = linspace(0, 1, SLMm/2);
colors1 = parula(num_NA);

eff_all_x = zeros(num_x ,num_NA);
figure; hold on;
for n_na = 1:num_NA
    sin_alpha = NA_eff_plot(n_na)/obj_RI;
    phase = obj_RI * k * sin_alpha * rho;
    phase = phase - min(phase);

    for n_x = 1:num_x
        %pix_levels = floor((abs(z_range(n_z)) * phase)/(2*pi));
        pix_levels = floor(floor((abs(x_range(n_x)) * phase)/(pi))/2);

        [C,level_changes, ic] = unique(pix_levels, 'last');
        level_counts = diff([0; level_changes]);

        level_eff = (sin(pi./level_counts)./(pi./level_counts)).^2;
        level_frac_areas = level_counts/sum(level_counts);

        eff_all_x(n_x, n_na) = sum(level_eff.*level_frac_areas);
    end
    plot(x_range/1e-6, eff_all_x(:,n_na), 'color', colors1(n_na,:), 'Linewidth', 2)
end
legend(num2str(NA_eff_plot'), 'location', 'southwest')
xlabel('Lateral diffraction distance (um)')
ylabel('Diffraction efficiency')
xlim('tight')
ylim([0 1]);
title(sprintf('Lateral diffraction efficiency vs NAeff, for %d pixel SLM', SLMm))

%% max lateral efficiency 

num_pat = numel(pat_pixels);
num_NA = numel(NA_eff_comp);

colors1 = parula(num_pat+1);

dist_all = zeros(num_NA, num_pat);
figure; hold on;
for n_pat = 1:num_pat
    rho = linspace(0, 1, pat_pixels(n_pat)/2);
    
    for n_na = 1:num_NA
        sin_alpha = NA_eff_comp(n_na)/obj_RI;
        phase = obj_RI * k * sin_alpha * rho;
        phase = phase - min(phase);

        temp_eff = 1;
        temp_x = 0;
        
        while temp_eff > eff_lim
            temp_x = temp_x + d_x;
            %pix_levels = floor((abs(z_range(n_z)) * phase)/(2*pi));
            pix_levels = floor(floor((temp_x * phase)/(pi))/2);

            [C,level_changes, ic] = unique(pix_levels, 'last');
            level_counts = diff([0; level_changes]);

            level_eff = (sin(pi./level_counts)./(pi./level_counts)).^2;
            level_frac_areas = level_counts/sum(level_counts);

            temp_eff = sum(level_eff.*level_frac_areas);
        end
        dist_all(n_na, n_pat) = temp_x - d_x;
    end
    plot(dist_all(:, n_pat)/1e-6, NA_eff_comp, 'Linewidth', 2, 'color', colors1(n_pat,:));
end
legend(num2str(pat_pixels'))
xlabel(sprintf('Diffraction distance (um)'))
ylabel('NAeff')
ylim([NA_eff_comp(1) NA_eff_comp(end)]);
xlim([0 max_dist])
title(sprintf('Distance at %d%% lateral diffraction efficiency vs NAeff', eff_lim*100))

%% eff NA vs resolution

NA_eff = 0.2:0.01:1.05;

resolution_lateral = (0.61*wavelength)./(NA_eff);
resolution_axial = (2*wavelength)./(NA_eff.^2);

figure; hold on;
plot(resolution_lateral/1e-6, NA_eff, 'Linewidth', 2);
plot(resolution_axial/1e-6, NA_eff, 'Linewidth', 2);
xlabel('Resolution (um)')
ylim([NA_eff(1) NA_eff(end)])
ylabel('NAeff')
legend({'Lateral (x-y)', 'Axial (z)'})
title(sprintf('Rayleigh resolution vs NAeff at %.0fnm', wavelength/1e-9))

%% zernike orthogonality

d_rho = 0.000001;
x_loc = 0:d_rho:1;
rho = abs(x_loc);

y1 = rho.^2;

y2 = rho.^4;

zer02 = sqrt(3) * (2*rho.^2 - 1); % 

zer04 = sqrt(5) * (6*rho.^4 - 6*rho.^2 + 1); % 

zer06 = sqrt(15) * (20*rho.^6- 30*rho.^4+ 12*rho.^2- 1);

figure; hold on;
plot(x_loc, zer02)
plot(x_loc, zer04)
plot(x_loc, zer06)

2*pi*sum(zer02.*rho*d_rho)


figure;
plot(rho, zer04 - zer02)


min(zer02)

max(zer02)


%% defoucs





















