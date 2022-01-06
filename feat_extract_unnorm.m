function features = feat_extract_unnorm(struct)



fields = string(fieldnames(struct));
features = [];
for j = 2:length(fields)
    % extract data from structure
    load_var = struct.(fields(j,:)).load;
    activities = struct.(fields(j,:)).activities;

    
   % check the person activities of the day - binary features
   if iscell(activities)
       activity = split(activities, ',');
       working_day = 0;
       sport = 0;
       stayed_home = 0;
       late_hangout = 0;
       studying_day = 0;
       family_time = 0;
       day_hangout = 0;
       for i = 1:length(activity)
           if strcmp(activity{i},'עבודה\מחקר') | strcmp(activity{i},'עבודה/מחקר')
               working_day = 1;

           elseif strcmp(activity{i},'ספורט')
               sport = 1;

           elseif strcmp(activity{i},'נשארתי בבית כל היום')
               stayed_home = 1;

           elseif strcmp(activity{i},'בילוי מאוחר')
               late_hangout = 1;

           elseif strcmp(activity{i},'לימודים')
               studying_day = 1;

           elseif strcmp(activity{i},'משפחה')
               family_time = 1;

           elseif strcmp(activity{i}, 'בילוי')
               day_hangout = 1;
           end
       end
   else
       working_day = nan;
       sport = nan;
       stayed_home = nan;
       late_hangout = nan;
       studying_day = nan;
       family_time = nan;
       day_hangout = nan;
   end

    feat_vec = [load_var working_day sport stayed_home late_hangout studying_day family_time day_hangout];

    features(end+1,:) = feat_vec;
end
