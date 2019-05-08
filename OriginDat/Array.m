

[filename,pathname] = uigetfile('*.dat');

filename = strcat(pathname,filename);
fid = fopen(filename);
fseek(fid,0,'eof');
filelength = ftell(fid);
% fseek(fid,112,'bof');
fseek(fid,0,'bof');
% [A,count]=fread(fid,(filelength-112)/2,'uint16');
[A,count]=fread(fid,(filelength)/4,'float32');
fclose(fid);
A = reshape(A,6,count/6);
x = ([A(1,:);A(2,:);A(3,:);A(4,:);A(5,:);A(6,:)])*5000/32768;

for i=1:6
    figure(i);
    plot(x(i,:),'b');
    grid on;
    hold on;
end


 



