% ���ֵ�ĺ���Ҫ�Ż���
function val = peakValue(pv, y)


val = pv - mean(y(1:3,1:floor(length(y)/8)),2);   % mean(y(1:3,1:floor(length(y)/8)),2)

