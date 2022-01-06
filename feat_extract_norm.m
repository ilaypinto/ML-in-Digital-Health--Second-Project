function feat_mat = feat_extract_norm(struct, call_norm_func)

% if call_norm_func
%     [means, stds] = norm_factors(struct);
% end

fields = string(fieldnames(struct));
feat_mat = [];
for j = 2:length(fields)
    % extract data from structure
    wifi = struct.(fields(j,:)).wifi;
    bluetooth = struct.(fields(j,:)).bluetooth;
    location = struct.(fields(j,:)).location;
    light = struct.(fields(j,:)).light;
    calls = struct.(fields(j,:)).calls;
    battery = struct.(fields(j,:)).battery;
    activity = struct.(fields(j,:)).activity;
    screen = struct.(fields(j,:)).screen;
    sleep_time = struct.(fields(j,:)).sleep_time;
    wake_time = struct.(fields(j,:)).wake_time;
    load_var_norm = struct.(fields(j,:)).load;


    % get the label of the day - weekend or not
    label = weekday(struct.(fields(j,:)).date);
    if label <= 5
        label = 0;
    else
        label = 1;
    end
    
    % sleeping features
    if isnan(sleep_time)
        sleep_duration = nan;
    elseif sleep_time > 0.5
        sleep_duration = 1 - sleep_time + wake_time;
    else
        sleep_duration = wake_time - sleep_time;
    end


    % wifi
    if isempty(wifi) %|| length(unique(wifi{:,1})) < 30
        wifi_sum = nan;
        no_wifi = nan;
    else
        wifi_sum = size(unique(wifi(~strcmp(wifi{:,2}, 'Not found'),2)),1); % num of wifi found that day
        no_wifi = sum(~strcmp(wifi{:,2}, 'Not found'));
    end

    % bluetooth
    if isempty(bluetooth) %|| length(unique(bluetooth{:,1})) < 30
        bluetooth_sum = nan;
    else   
        bluetooth_sum = size(bluetooth,1);  % num of BT devices found that day
    end

    % screen
    if isempty(screen)
        on_off_switches = 0;                   % number of changes of Screenstate on/off
    else
        on_off_switches = 0;
        for i = 1:size(screen,1)-1
            if strcmp(screen{i,2},'on')
                if strcmp(screen{i+1,2},'off')
                    on_off_switches = on_off_switches+1;
                end
            else
                if strcmp(screen{i+1,2},'on')
                    on_off_switches = on_off_switches+1;        
                end                                             % ^^^line 28 - if it says 'on' and the next one 'off' then add one^^^
                % ^^^line 33 - if it says 'off' and the next one 'on' then add one^^^
            end
        end
    end

    % battery
    if isempty(battery) %|| length(unique(battery{:,1})) < 30
        battery_start = nan;
        battery_end = nan;
        battery_mid = nan;
        first_charge_time = nan;
    else
        battery_start = str2double(battery{1,2});                  % battery % at start of the day
        battery_end = str2double(battery{end,2});                  % battery % at end of the day
        battery_mid = str2double(battery{round((size(battery,1))/2),2}); % battery % at mid of day

        first_charge_time = 0;                                % first time connected to
        for i=1:size(battery,1)                               % a charger
            if strcmp(battery{i,4},'usbCharge') || strcmp(battery{i,4},'acCharge')
                first_charge_time = battery{i,1};
                break
            end
        end
    end
    
    % calls
    if isempty(calls)
        calls_num = 0;
        calls_sum = 0;
        calls_max = 0;
        calls_max_time = nan;
    else
        calls_num = size(calls,1);   % number of calls in a day
        calls_sum = sum(str2double(calls{:,2}));                              % sum of sec on the phone per day
        [M,I] = max(str2double(calls{:,2}));
        calls_max = M;                                     % longest call(in sec)
        calls_max_time = calls{I,1}; % time of longest call
    end

    % activity
    in_vehicle = sum(strcmp(activity{:,3},'IN_VEHICLE')); % times a day in vehicle

    on_foot = sum(strcmp(activity{:,3},'ON_FOOT'));    % times a day on foot
    
    tilting = sum(strcmp(activity{:,3},'TILTING'));    % times a day tilting
    if isempty(in_vehicle)
        in_vehicle = 0;
    end
    if isempty(on_foot)
        on_foot = 0;
    end
    if isempty(on_foot)
        on_foot = 0;
    end

    % location
    if isempty(location) %|| length(unique(location{:,1})) < 30
        location_sum = nan;
        location_max = nan;
        location_max_time = nan;
    else
        location_sum = sum(str2double(location{:,2})); % sum of movement in a day
        [M,I] = max(str2double(location{:,3}));
        location_max = M;                       % max movement
        location_max_time = location{I,1};      % max movement time
    end

    % light
    if isempty(light) %|| length(unique(light{:,1})) < 30
        light_sum = 0;
    else
        func = @(x)str2double(x);
        table_values = varfun(func,light(:,2));
        light_sum = sum(table_values{:,1});
    end

   
    feat_vec = [wifi_sum no_wifi bluetooth_sum on_off_switches battery_start...
    battery_mid battery_end first_charge_time calls_num calls_sum...
    calls_max calls_max_time in_vehicle on_foot tilting location_sum...
    location_max location_max_time sleep_time wake_time sleep_duration light_sum load_var_norm label];

    feat_mat = cat(1,feat_mat,feat_vec);
end

for i = 1:(length(feat_vec) - 1)
    not_nan_idx = find(~isnan(feat_mat(:,i)));
    L = length(not_nan_idx);
    if L > 10
        k = 10;
    elseif L == 0
        continue
    else
        k = L;
    end
    
    % calculate the mean and std of the features from random days without any
    % nan values
    rng('default')  
    indices = randperm(L,k);
    
    temp_feat = feat_mat(not_nan_idx(indices), i);
    means = mean(temp_feat);
    stds = std(temp_feat);
    feat_mat(not_nan_idx, i) = (feat_mat(not_nan_idx, i) - means)./stds;  % normalize the data of each person
    feat_mat(feat_mat == inf) = 100;
end

% if call_norm_func
%     feat_mat(:, 1:end-1) = (feat_mat(:, 1:end-1) - means)./stds;
% end
end


