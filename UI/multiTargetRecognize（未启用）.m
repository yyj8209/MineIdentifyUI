function multiTargetRecognize(app)

% 提取特征值。
% clear;

    % % 选择数据文件路径
    FolderName = uigetdir('..\OriginDat','请选择数据文件路径。');   
    % FolderName = 'E:\matlab\OriginDat\20190305';    % 调试时用这个默认路径。
    A = dir(fullfile(FolderName,'*.dat'));
    % %列表选择对话框
    AllFileNames = cell(size(A));
    for i=1:size(A,1)
        AllFileNames{i,1} = A(i,1).name;
    end
    [Sel,Ok]=listdlg('liststring',AllFileNames,...
        'listsize',[360 480],'OkString','确定','CancelString','取消',...
        'promptstring','请选择数据文件','name','请选择数据文件（多选）',...
        'selectionmode','multiple');
    if(Ok == 0)
        msgbox('您取消了选择文件。');
        return;
    end
    FileName = A(Sel,1);
    FullName = A(Sel,1);
    FileNumSel = size(FileName,1);
    for k=1:FileNumSel
        FullName(k,1).name = strcat(FolderName,'\', FileName(k,1).name);
    end

    % ----------------- 对每个数据文件完成以下几项工作：----------------- %
    % 1、读取前三行，即三个有效通道的数据；
    % 2、提取每个通道的第一个极值增量、均值和方差；
    % 3、将上述三个增量，增量决定的斜率，及斜率比、增量比；
    % 4、进行目标识别，并将数据保存到Excel表格。
    % ----------------------------------------------------------------- %
    Fpass = 1;   Fstop = 5;  fs = 100; rpL = 1; rsL = 60;
    [bL,~] = LPFDesign(Fpass,Fstop,fs,rpL,rsL);
    Header = {'文件名','CH1','CH2','CH3','Kr','V1/V3','VAR1','VAR2','VAR3'};   % 8个特征值
    Data = cell(FileNumSel,9);


    for i = 1:FileNumSel
    % 1、读取前三行，即三个有效通道的数据；
    % ----------------------------------------------------------------- %
        fid = fopen(FullName(i,1).name);
        fseek(fid,0,'eof');
        filelength = ftell(fid);
        fseek(fid,0,'bof');
        [A,count]=fread(fid,(filelength)/4,'float32');
        fclose(fid);
        A = reshape(A,6,count/6);
        x = ([A(1,:);A(2,:);A(3,:)])*5000/32768;

    % 2、提取'通道1峰值V1','通道2峰值V2','通道3峰值V3','Kr=斜率1/斜率2','V1/V3','均值EV1','EV2','方差DV1','DV2'。
    % ----------------------------------------------------------------- %
    %     m = mean(x(:,20:150),2);
        y = zeros(size(x));
        Sign = 1;
        for k1 = 3:-1:1     % x 由3个通道的数据向量组成。
            x1 = x(k1,:);
            % 增加一个去除脉冲的函数（假定最多只有一个脉冲）。基本思路是，跳跃大于500时，确定该点为脉冲，去除之。2019.03.19
            [loc] = find(abs(diff(x1))>200);   % 
            if(~isempty(loc))     % 这里去脉冲点。若有多个，可用find函数。
                x1(loc+1) = x1(loc+3);
            end
            x2 = x1 - mean(x1);      % 去直流。

            y1 = [zeros(1,length(bL)),x2,zeros(1,length(bL))];    % 滤波器对信号的首尾产生畸变，采用加数据法消除。
            y2 = filtfilt(bL,1,y1);                               % 进行低通滤波
            y3 = y2(length(bL)+1:length(y2)-length(bL));
            y(k1,:) = y3 - mean(y3) + mean(x1);    % 到这一步已经恢复了信号。

            [Value] = find(y(k1,:) >  mean(x1));
            if(sum(Value)>0.5*length(y(k1,:)))
                Sign = -1;    % 谷的形状，需要反转来求峰值。
            end

        end
        % 以通道1的最大值点，确定为判决用的点。
        [~,lsor] = findpeaks(Sign*y(1,:),'SortStr','descend');
        pv = y(1:3,lsor(1));     % 取峰值最大的点。
        PeakValue = peakValue(pv,y);     % 用50到150点的均值代表向量均值。

        str = FileName(i,1).name;
        FileStr = str(1:strfind(str,'.dat')-1);
        K1 = PeakValue(2) - PeakValue(1);
        K2 = PeakValue(3) - PeakValue(2);
        Kr = abs(K2/K1);
        Data{i,1} = FileStr;
        Data{i,2} = PeakValue(1);
        Data{i,3} = PeakValue(2);
        Data{i,4} = PeakValue(3);
        Data{i,5} = Kr;
        Data{i,6} = PeakValue(1)/PeakValue(3);
        Data{i,7} = std(y(1,:));
        Data{i,8} = std(y(2,:));
        Data{i,9} = std(y(3,:));    % var 改成了 std    2019.04.27

    end
    % 3、保存到Excel表格。
%     % ----------------------------------------------------------------- %
%     t = datetime('now','Format','yyyy-MM-dd''-''HHmmss');
%     [file,path] = uiputfile(['.\特征值',datestr(t,'yyyymmdd-HHMMSS'),'.xls']);
%     if(isequal(filename,0) || isequal(pathname,0)) 
%         return; 
%     end
%     [SUCCESS,~] = xlswrite([path,file],Header,'特征值','A1');          % 写入excel文件。
%     xlswrite([path,file],Data,'特征值','A2');          % 写入excel文件。
%     if(SUCCESS~=1)
%         msgbox('请确认 xls 已关闭后再试。');
%     else
%         msgbox('数据保存成功！');
%     end
%     SavePath = [path,file];
end   % end of function CharacteristicValue.
% ================================ 增加几个函数 ============================== %

