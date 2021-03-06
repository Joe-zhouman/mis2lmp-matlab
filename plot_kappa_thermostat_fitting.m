%% calculate thermal resistence for MD simulation with ansymmetrical thermostat and non-peridic boundary
clc,clear, close all; font_size=15;

file_id = 3;
%% define defect type id to represente defect types
%       1.   random antisite
%       2.   neighbor antisite
%       3.   B substitute N
%       4.   N substitute B
%       5.   test  
defect_type_id = 3;
defect_type  = defect_id2type( defect_type_id );
for coverage = 4  
    file_path = ['D:\zm_documents\LAMMPS\hBN_defects\test',num2str(file_id),'\',defect_type,'\',num2str(coverage)];
    %ii = coverage/2 + 1;
    %data from MD simulations
    %metal unit ev ps bar A
    log_file = [file_path,'\log.lammps'];
fileID=fopen(log_file);
lammps_log = zeros(1,3);
len_header = 2300;
N = 2301;
formatSpec='%n %n %n %n %n %n %n %n %n';
flag = 0;
while 1
        try
                C=textscan(fileID,formatSpec,N,'HeaderLines',len_header,'Delimiter','\t');
                check_step = C{1}(end);
                if check_step == 4000000              	
                        for idx = 1 : 3
                                lammps_log(idx) = C{6 + idx}(end);
                        end
                        break
                end
        catch ME
                rethrow(ME)              
        end
        fclose(fileID);
end
disp(check_step)
    for ii = 0 : 2
    blocks = 40 *2 ^ ii;
        
    num_blocks = 41;                        % 块的个数
    Lx =  lammps_log(3);                 % 输运方向长度
    Ly =  50.2296;                             %宽度
    Lz = 3.3 ;                             %厚度
    dt = 0.25e-3;                           %时间步长
    delta_E = 4;

    

    timesteps = 4000000;                    %时间步数
    ave_timesteps = 1000000;                 %计算平均温度的步数

    %计算一些参数
    file_name = [file_path,'/',num2str(blocks),'.temp'];

    num_outputs = timesteps/ave_timesteps;  % 输出块温度的次数
    dx = Lx / num_blocks;                   % 每个块的长度

    t0 =ave_timesteps*dt;                   % 每次输出数据增加的模拟时间
    factor = blocks/(num_blocks-1);
    % 非平衡模拟时间
    t= t0 * (1 : num_outputs);
    % 块坐标
    x = (1 : blocks) /factor* dx; % 一行
    x = x.';                   % 一列

    %从LAMMPS输出文件中提取块温度
    [Chunk Coord1 Ncount v_TEMP] ...
        = textread(file_name, '%n%n%n%n', 'headerlines', 3, 'emptyvalue', 0);
    temp = [Chunk Coord1 Ncount v_TEMP]; 
    nall = length(temp) / (blocks+1);
    clear Chunk Coord1 Ncount v_TEMP;
    for i =1:nall
        temp((i-1)*num_blocks+1,:)=[];
    end
    temp = reshape(temp(:, end), blocks, num_outputs);
    temp1 = zeros(blocks,num_outputs);
    kappa_1 = zeros(4,1);
    

    
    
    

    % 对输出次数作循环，计算温度梯度和热导率
    for n = 1 : num_outputs
        %iii = (ii-1) * num_outputs + n;
        
            
            E_left=lammps_log(1);
            E_right=lammps_log(2);
            if E_left ==0
                dE = delta_E;
            else
                dE=(E_left-E_right)/2/ave_timesteps/4 / dt;
            end
            power = dE * 1.6e-7;                    % 功率 eV/ps -> W
            A = Ly*Lz * 1.0e-20;                    % 横截面积 A^2 -> m^2
            Q = power / A  ;                       % 热流密度 W/m^2
        % 确定拟合区间（具体问题具体分析）
        index_1 = 8*factor : blocks-8*factor;              % 左边除去热源后的块指标


        % 拟合温度分布
       p1 = polyfit(x(index_1),temp(index_1, n),1);

        % 得到温度梯度
        gradient_1 = - p1(1) * 1.0e10; % K/A -> K/m


        % 得到热导率
        kappa_1(n) = - Q / gradient_1;

      
        % 画温度分布以及拟合曲线
        figure
        plot(x(1*factor+1:end-2*factor), temp(1*factor+1:end-2*factor, n), 'bo', 'linewidth', 2);
        hold on;
        x1=x(index_1(1)) : 0.1 : x(index_1(end));

        plot(x1, p1(2)+p1(1)*x1, 'r-', 'linewidth', 2);

        legend('MD','location','best');
        set(gca, 'fontsize', font_size);
        title (['t = ', num2str(t0 * n), ' ps']);
        xlabel('x (nm)');
        ylabel('T (K)');
     end

    % 热导率的时间收敛测试
%     kappa_1;
%     figure;
%     plot(t, kappa_1, ' ko', 'linewidth', 2);
%     set(gca, 'fontsize', font_size);
%     xlabel('t (ps)');
%     ylabel('\kappa (W/mK)');
%     legend('average');

    % 报道结果（具体问题具体分析）
    kappa_1% = kappa_1'  
    kappa  = mean( abs( kappa_1(1:end)) )

%     figure(n+2)
%     boxplot(temp(4:end-3,:)','PlotStyle','compact')
%     xlabel('x (nm)');
%     ylabel('T (K)');
    end
end
% figure
% hold on
% 
% x0 = 0 : 2 : 10;
% y0 = kappa./kappa(1) * 100;
% 
% plot(x0,1./y0,'ro')
% 
% xq = linspace(0,10.5,100);
% yq = interp1(x0,y0,xq,'spline');
% 
% plot(xq,1./yq);
% xlim ( [0,10.5]);
% %ylim ([0,110]);
