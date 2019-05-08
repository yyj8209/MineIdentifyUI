function targetRecognize(app,FullName,FileName)

%% �������������á�
load(app.FileCoef);
inputps = Coef.inputps;
w1 = Coef.w1;
b1 = Coef.b1;
w2 = Coef.w2;
b2 = Coef.b2;

load(app.FileSettings);
INPUTNUM    = InputLayerNum;
OUTPUTNUM   = OutputLayerNum;     % ���ࣺ4��Ϊ����š�С���š�Ŀ�ꡢ������3��Ϊ����š�С���š�Ŀ�ꡣ���ݾ��飬����������ǰʶ��   2019.05.03
FileNumSel = size(FileName,1);

%% ��ȡ����ֵ
% ----------------- ��ÿ�������ļ�������¼������----------------- %
% 1����ȡǰ���У���������Чͨ�������ݣ�
% 2����ȡÿ��ͨ���ĵ�һ����ֵ�����ͷ����8������ֵ��'CH1','CH2','CH3','Kr','V1/V3','VAR1','VAR2','VAR3'��
% 3��
% 4��
% ----------------------------------------------------------------- %
Fpass = 1;   Fstop = 5;  fs = 100; rpL = 1; rsL = 60;
[bL,~] = LPFDesign(Fpass,Fstop,fs,rpL,rsL);
% Header = {'�ļ���','CH1','CH2','CH3','Kr','V1/V3','VAR1','VAR2','VAR3'};   % 8������ֵ
Data = cell(FileNumSel,9);


for i = 1:FileNumSel
% 1����ȡǰ���У���������Чͨ�������ݣ�
% ----------------------------------------------------------------- %
    fid = fopen(FullName(i,1).name);
    fseek(fid,0,'eof');
    filelength = ftell(fid);
    fseek(fid,0,'bof');
    [A,count]=fread(fid,(filelength)/4,'float32');
    fclose(fid);
    A = reshape(A,6,count/6);
    x = ([A(1,:);A(2,:);A(3,:)])*5000/32768;

% 2����ȡ'ͨ��1��ֵV1','ͨ��2��ֵV2','ͨ��3��ֵV3','Kr=б��1/б��2','V1/V3','��ֵEV1','EV2','����DV1','DV2'��
% ----------------------------------------------------------------- %
%     m = mean(x(:,20:150),2);
    y = zeros(size(x));
    Sign = 1;
    for k1 = 3:-1:1     % x ��3��ͨ��������������ɡ�
        x1 = x(k1,:);
        % ����һ��ȥ������ĺ���������˼·�ǣ���Ծ����500ʱ��ȷ���õ�Ϊ���壬ȥ��֮��2019.03.19
        [loc] = find(abs(diff(x1))>200);   % 
        if(~isempty(loc))     % ����ȥ����㡣���ж��������find������
            x1(loc+1) = x1(loc+3);
        end
        x2 = x1 - mean(x1);      % ȥֱ����

        y1 = [zeros(1,length(bL)),x2,zeros(1,length(bL))];    % �˲������źŵ���β�������䣬���ü����ݷ�������
        y2 = filtfilt(bL,1,y1);                               % ���е�ͨ�˲�
        y3 = y2(length(bL)+1:length(y2)-length(bL));
        y(k1,:) = y3 - mean(y3) + mean(x1);    % ����һ���Ѿ��ָ����źš�

        [Value] = find(y(k1,:) >  mean(x1));
        if(sum(Value)>0.5*length(y(k1,:)))
            Sign = -1;    % �ȵ���״����Ҫ��ת�����ֵ��
        end

    end
    % ��ͨ��1�����ֵ�㣬ȷ��Ϊ�о��õĵ㡣
    [~,lsor] = findpeaks(Sign*y(1,:),'SortStr','descend');
    pv = y(1:3,lsor(1));     % ȡ��ֵ���ĵ㡣
    PeakValue = peakValue(pv,y);     % ��50��150��ľ�ֵ����������ֵ��

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
    Data{i,9} = std(y(3,:));    % var �ĳ��� std    2019.04.27

end

%% �ġ�BP���������?
% ?��ѵ���õ�BP��������������źţ����ݷ���������BP���������������

% �����źŷ���
input_test = Data{1:FileNumSel,2:(INPUTNUM+1)};
inputn_test = mapminmax('apply',input_test,inputps);
fore = zeros(OUTPUTNUM,FileNumSel);
for i=1:FileNumSel  %TOTALSAMPLE
    %���������
    I    = (inputn_test(:,i)'*w1')+ b1';
    Iout =1./(1+exp(-I));

    fore(:,i)=w2'*Iout'+b2;
end
[~,OutputType]=max(fore);

%% ���б�������������溯��������������ĺ�����ʵ����ʾ��
% ��Table����ʾ
number = (1:length(OutputType))';
filename = FileName.name;
results = cell(length(OutputType),1);
res = {'�����','С����','��','��Ŀ��'};
for i = 1:length(OutputType)
    results{i,1} = cell2mat(res(OutputType(i)));
end
TableData = table(number,cellstr(filename),results);
setTableView(app,TableData);


ax = app.UIAxes;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on'
plot(ax,[x',y']);
legend(ax,'ͨ��1','ͨ��2','ͨ��3','�˲�1','�˲�2','�˲�3','Location','NorthWest');
title(ax,['�����ļ���',FileStr]);
% grid on;

