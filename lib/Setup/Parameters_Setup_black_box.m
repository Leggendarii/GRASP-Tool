base_setup

% Control Parameters from excel file trom tuning tool
kp_outer_V_pu = parameter.Value(11);
ki_outer_V_pu = 1/parameter.Value(12);
kp_outer_P_pu = parameter.Value(13);
ki_outer_P_pu = 1/parameter.Value(14);
kp_inner_pu = parameter.Value(15);
ki_inner_pu = 1/parameter.Value(16);
kp_pll = parameter.Value(17);
ki_pll = 1/parameter.Value(18);
T1 = 1;
T2 = 1;


