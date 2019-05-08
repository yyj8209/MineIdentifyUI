function BPTrainMain(app)
%% 该代码为基于BP网络的语言识别
% clc
% clear
tic
h = waitbar(0,'正在计算，请稍等...');

% 一、数据选择和归一化
% 每组数据为25维，第1维维类别标识，后8维为特征信号。3维输出，代表3种结果：干扰、目标、空
% 抽取180组数据作为训练数据，42 组数据作为测试数据，并对数据进行归一化处理。
% 根据类别标识设定每组信号的期望输出值，如标识类为1时，期望输出向量为[1 0 0]。
 
%% 参数设置
load(app.FileSettings);
INPUTNUM    = InputLayerNum;
MIDNUM      = MiddleLayerNum;
OUTPUTNUM   = OutputLayerNum;     % 分类：4类为大干扰、小干扰、目标、背景；3类为大干扰、小干扰、目标。根据经验，背景可以提前识别。   2019.04.16
TRAINSAMPLE = TrainSampleNum;
TESTSAMPLE  = TestSampleNum;
TOTALSAMPLE = TRAINSAMPLE + TESTSAMPLE;
THETA       = 0.05;
ALPHA       = 0.01;
LOOPNUM     = LoopNum;
ISRANDOM    = 1;     % 0 表示TESTSAMPLE测试样本在表最后，

% INPUTNUM    = 8;
% MIDNUM      = 12;
% OUTPUTNUM   = 3;     % 分类：4类为大干扰、小干扰、目标、背景；3类为大干扰、小干扰、目标。根据经验，背景可以提前识别。   2019.04.16
% TOTALSAMPLE = 344;
% TRAINSAMPLE = 270;
% TESTSAMPLE  = TOTALSAMPLE - TRAINSAMPLE;
% THETA       = 0.05;
% ALPHA       = 0.01;
% LOOPNUM     = 600;
% ISRANDOM    = 0;     % 0 表示TESTSAMPLE测试样本在表最后，
%% 训练数据预测数据提取
% 载入信号
% dat = xlsread('数据导出20190322-080708.xls','4类优化样本',['A2:I',num2str(TOTALSAMPLE+1)]);
dat = xlsread(FileSavePath,SheetSelected,['A2:I',num2str(TOTALSAMPLE+1)]);
% 从 1 到 TOTALSAMPLE 间随机排序，便于随机取训练样本。
k = rand(1,TOTALSAMPLE);
[~,n] = sort(k);
if(~ISRANDOM)
    TestFile   = (TRAINSAMPLE+1:TOTALSAMPLE)';
else
    TestFile   = (n(TRAINSAMPLE+1:TOTALSAMPLE))';
end
% 输入输出数据
X1 = dat(:,2:INPUTNUM+1);
Ytmp = dat(:,1);
 
% 把输出从1个变成 3 个
Y = zeros(TOTALSAMPLE,OUTPUTNUM);
if(OUTPUTNUM == 4)
    for i=1:TOTALSAMPLE
        switch Ytmp(i)
            case 1  
                Y(i,:) = [1 0 0 0];
            case 2  
                Y(i,:) = [0 1 0 0];
            case 3  
                Y(i,:) = [0 0 1 0];
            case 4  
                Y(i,:) = [0 0 0 1];
            otherwise
        end
    end
end

if(OUTPUTNUM == 3)
    for i=1:TOTALSAMPLE
        switch Ytmp(i)
            case 1  
                Y(i,:) = [1 0 0];
            case 2  
                Y(i,:) = [0 1 0];
            case 3  
                Y(i,:) = [0 0 1];
            otherwise
        end
    end
end
 
% 随机提取 TRAINSAMPLE 个样本为训练样本，TOTALSAMPLE 个样本为预测样本
input_train  = X1(n(1:TRAINSAMPLE),:)';
output_train = Y(n(1:TRAINSAMPLE),:)';
input_test   = X1(TestFile,:)';
output_test  = Y(TestFile,:)';

% 二、BP神经网络结构初始化 
% 根据特征信号特点确定BP神经网络的结构为 8-25-3，随机初始化BP神经网络权值和阈值。

% 输入数据归一化
[inputn,inputps] = mapminmax(input_train);   % y = (ymax-ymin)*(x-xmin)/(xmax-xmin) + ymin;

% 网络结构初始化
 
%权值初始化
w1   = rands(MIDNUM,INPUTNUM);
b1   = rands(MIDNUM,1);
w2   = rands(MIDNUM,OUTPUTNUM);
b2   = rands(OUTPUTNUM,1);

waitbar(0.1,h);
%% 三、BP神经网络训练
% 用训练数据训练BP神经网络，在训练过程中根据网络预测误差调整网络的权值和阈值。
% [E,w1,b1,w2,b2] = BPTrain(LOOPNUM,TRAINSAMPLE,inputn,w1,b1,w2,b2,output_train,THETA);
[E,w1,b1,w2,b2] = BPTrain_mex(LOOPNUM,TRAINSAMPLE,inputn,w1,b1,w2,b2,output_train,THETA);

t1 = toc;
waitbar(0.8,h);

%% 四、BP神经网络分类?
% ?用训练好的BP神经网络分类特征信号，根据分类结果分析BP神经网络分类能力。

% 特征信号分类
inputn_test = mapminmax('apply',input_test,inputps);
fore = zeros(OUTPUTNUM,TESTSAMPLE);
for i=1:TESTSAMPLE%TOTALSAMPLE
    %隐含层输出
    I    = (inputn_test(:,i)'*w1')+ b1';
    Iout =1./(1+exp(-I));

    fore(:,i)=w2'*Iout'+b2;
end

%% 五、结果分析
% 分析实验结果。画出误差图。展示准确率。
% 根据网络输出找出数据属于哪类
SampleType = Ytmp(TestFile);

[~,OutputType]=max(fore);
[Loc, ~] = find(OutputType'-SampleType);
TypeNum = zeros(1,OUTPUTNUM);
ErrorNum = zeros(1,OUTPUTNUM);

if(OUTPUTNUM == 4)
    for k = 1:TESTSAMPLE
        switch SampleType(k)
            case 1
                TypeNum(1) = TypeNum(1)+1;
            case 2
                TypeNum(2) = TypeNum(2)+1;
            case 3
                TypeNum(3) = TypeNum(3)+1;
            case 4
                TypeNum(4) = TypeNum(4)+1;
        end
    end
    for k = 1:length(Loc)
        switch SampleType(Loc(k))
            case 1
                ErrorNum(1) = ErrorNum(1)+1;
            case 2
                ErrorNum(2) = ErrorNum(2)+1;
            case 3
                ErrorNum(3) = ErrorNum(3)+1;
            case 4
                ErrorNum(4) = ErrorNum(4)+1;
        end
    end
end

if(OUTPUTNUM == 3)
    for k = 1:TESTSAMPLE
        switch SampleType(k)
            case 1
                TypeNum(1) = TypeNum(1)+1;
            case 2
                TypeNum(2) = TypeNum(2)+1;
            case 3
                TypeNum(3) = TypeNum(3)+1;
        end
    end
    for k = 1:length(Loc)
        switch SampleType(Loc(k))
            case 1
                ErrorNum(1) = ErrorNum(1)+1;
            case 2
                ErrorNum(2) = ErrorNum(2)+1;
            case 3
                ErrorNum(3) = ErrorNum(3)+1;        
        end
    end
end

waitbar(1,h,'计算完成');

%正确率
% 画出误差图
ax = app.UIAxes;
plot(ax,E);

% tb = axtoolbar(ax,{'zoomin','zoomout','datacursor','restoreview'});     % axtoolbar(ax,{'zoomin','zoomout','restoreview'});
radio = 1-ErrorNum./TypeNum;
xlabel(ax,['训练次数：',num2str(LOOPNUM),'次，用时：',num2str(t1),' 秒']);
ylabel(ax,'误差曲线');

if(OUTPUTNUM == 4)
    title(ax,['识别正确率， 目标-->',num2str(radio(3)*100), '%',newline,...
        '大干扰-->',num2str(radio(1)*100),'%， 小干扰-->',num2str(radio(2)*100),...
        '%， 背景-->',num2str(radio(4)*100),'%']);
end

if(OUTPUTNUM == 3)
    title(ax,['识别正确率， 目标-->',num2str(radio(3)*100),'%',newline...
        '大干扰-->',num2str(radio(1)*100),'%， 小干扰-->',num2str(radio(2)*100),'%']);

end
%% 六、保存结果
% 把权值输出到主界面函数，再在主界面提供的按钮保存。
close(h);
Coef.inputps = inputps;
Coef.w1 = w1;
Coef.b1 = b1;
Coef.w2 = w2;
Coef.b2 = b2;
setCoefFile(app,Coef);
% save('CoefFile','w1','b1','w2','b2');

% 把判别结果输出到主界面函数，再由主界面的函数来实现显示。
[~,t,~] = xlsread(FileSavePath,SheetSelected,['J2:J',num2str(TOTALSAMPLE+1)]);
number = (1:length(OutputType))';
filename = t(TestFile);
results = cell(length(OutputType),1);
res = {'大干扰','小干扰','雷','无目标'};
for i = 1:length(OutputType)
    results{i,1} = cell2mat(res(OutputType(i)));
end
TableData = table(number,filename,results);
setTableView(app,TableData);
            
