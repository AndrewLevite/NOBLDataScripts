clear all
[dirname] = uigetdir('*.csv','Please choose CSV directory');
cd(dirname)
[dirname] = uigetfile('*.csv','Please choose CSV directory');

M = csvread(dirname);

SC1 = M(1:end,1);
SC2 = M(1:end,2);
SC3 = M(1:end,3);

SB1 = M(1:end,4);
SB2 = M(1:end,5);
SB3 = M(1:end,6);



subplot(3,3,1)
histogram(SC1)
hold on
histogram(SB1)
hold off
title('Set 1 , Set 1 Histogram')

subplot(3,3,2)
histogram(SC1)
hold on
histogram(SB2)
hold off
title('Set 1 , Set 2 Histogram')

subplot(3,3,3)
histogram(SC1)
hold on
histogram(SB3)
hold off
title('Set 1 , Set 3 Histogram')

%%%%%

subplot(3,3,4)
histogram(SC2)
hold on
histogram(SB1)
hold off
title('Set 2 , Set 1 Histogram')

subplot(3,3,5)
histogram(SC2)
hold on
histogram(SB2)
hold off
title('Set 2 , Set 2 Histogram')

subplot(3,3,6)
histogram(SC2)
hold on
histogram(SB3)
hold off
title('Set 2 , Set 3 Histogram')

%%%%

subplot(3,3,7)
histogram(SC3)
hold on
histogram(SB1)
hold off
title('Set 3 , Set 1 Histogram')

subplot(3,3,8)
histogram(SC3)
hold on
histogram(SB2)
hold off
title('Set 3 , Set 2 Histogram')

subplot(3,3,9)
histogram(SC3)
hold on
histogram(SB3)
hold off
title('Set 3 , Set 3 Histogram')



