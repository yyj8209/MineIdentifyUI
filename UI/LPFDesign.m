function [bL,NTapL] = LPFDesign(Fpass,Fstop,fs,rpL,rsL)
% function [bL,NTapL] = LPFDesign(fc,FpassL,FstopL,fs,rpL,rsL):设计低通滤波。
% 输入：Fpass 通带宽,Fstop 阻带宽,fs 采样速率,rpL 带内波动(dB),rs阻带衰减(dB)。
% 输出：bL 滤波器系数， NTapL 抽头个数。
rp = rpL;
rs = rsL;
% fs = 8000;
f = [Fpass Fstop];
a = [1 0];
dev = [(10^(rp/20)-1)/(10^(rp/20)+1)  10^(-rs/20)];
[NTapL,fo,ao,w] = firpmord(f,a,dev,fs);
bL = firpm(NTapL,fo,ao,w);

