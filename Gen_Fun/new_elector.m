function elec = new_elector

 C = textscan(fopen('realistic_1005.txt'),'%s  %f32 %f32 %f32');

elec = struct(...
    'labels',C{1},...
    'X',C{2},...
    'Y',C{3},...
    'Z',C{4});

end