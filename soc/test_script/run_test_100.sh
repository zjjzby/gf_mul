#! /bin/bash

data_width=163
digital=32
sample=100

b_data_width=$(( $(( $data_width / $digital + 1 )) * $digital ))
data_width_p1=$(( $data_width + 1 ))

echo "##############################"
echo TEST START
echo

loop=0
for((loop=0; loop<$sample; loop++))
do
	echo -n Sample $loop running .
	
	i=0
	j=0
	for((i=0; i<$data_width; i++))
	do
		a[$i]=$(( $RANDOM % 2 ))
		b[$i]=$(( $RANDOM % 2 ))
		g[$i]=0
	done
	
	g[0]=1; g[3]=1; g[6]=1; g[7]=1

	for((i=$data_width; i<$b_data_width; i++))
	do
		a[$i]=0
		b[$i]=0
		g[$i]=0
	done

	for((i=0; i<$data_width_p1; i++))
	do
		for((j=0; j<$data_width_p1; j++))
		do
			t_i_j=$(( $data_width_p1 * $i + $j ))
			t[$t_i_j]=0
		done
	done
	
	echo -n "."

	for((i=1; i<$data_width_p1; i++))
	do
		for((j=$data_width; j>0; j--))
		do
			t_i_j=$(( $data_width_p1 * $i + $j ))
			t_i1_m=$(( $data_width_p1 * $(( $i - 1 )) + $data_width ))
			g_j1=$(( $j - 1 ))
			b_mi=$(( $data_width - $i ))
			a_j1=$(( $j - 1 ))
			t_i1_j1=$(( $data_width_p1 * $(( $i - 1 )) + $j - 1 ))
			
			t[$t_i_j]=$(( $(( ${t[$t_i1_m]} & ${g[$g_j1]} )) ^ $(( ${b[$b_mi]} & ${a[$a_j1]} )) ^ $(( ${t[$t_i1_j1]} )) ))
		done
	done
	
	for((j=1; j<$data_width_p1; j++))
	do
		t_m_j=$(( $data_width_p1 * $data_width + $j ))
		t_result[$(( $j - 1 ))]=${t[$t_m_j]}
	done

	for((i=0; i<=5; i++))
	do
		value_t=""
		for((j=0; j<32; j++))
		do
			value_t=${t_result[$(($i * 32 + $j))]}$value_t
		done
		result_standard[$i]=0x$(echo "obase=16; ibase=2; $value_t"|bc)
	done
	
	echo -n "."

	for((i=0; i<=5; i++))
	do
		value_a=""
		value_b=""
		value_g=""
		for((j=0; j<32; j++))
		do
			value_a=${a[$(($i * 32 + $j))]}$value_a
			value_b=${b[$(($i * 32 + $j))]}$value_b
			value_g=${g[$(($i * 32 + $j))]}$value_g
		done
		./reg_rw_8k /dev/xdma0_user 0x$(echo "obase=16; $(($i * 4 + 4096))"|bc) w 0x$(echo "obase=16; ibase=2; $value_a"|bc) >> run.log
		./reg_rw_8k /dev/xdma0_user 0x$(echo "obase=16; $(($i * 4 + 4128))"|bc) w 0x$(echo "obase=16; ibase=2; $value_b"|bc) >> run.log
		./reg_rw_8k /dev/xdma0_user 0x$(echo "obase=16; $(($i * 4 + 4160))"|bc) w 0x$(echo "obase=16; ibase=2; $value_g"|bc) >> run.log
	done
	
	./reg_rw_8k /dev/xdma0_user 0x0000 w 0x100 >> run.log
	status=$(./reg_rw_8k /dev/xdma0_user 0x0000 w | awk '/Read/{print $8}')
	while [ $status = "0x00000200" ]
	do
		status=$(./reg_rw_8k /dev/xdma0_user 0x0000 w | awk '/Read/{print $8}')
	done
	if [ $status != "0x00000000" ]
	then
		echo " ERROR: FPGA status error."
		exit
	fi

	for((i=0; i<=5; i++))
	do
		declare -u result[$i]
		result[$i]=$(./reg_rw_8k /dev/xdma0_user 0x$(echo "obase=16; $(($i * 4 + 4256))"|bc) w | awk '/Read/{print $8}')
	done
	
	for((i=0; i<=5; i++))
	do
		declare +u result[$i]
		result[$i]=0x${result[$i]:2:8}
		if [ $((${result[$i]})) -eq $((${result_standard[$i]})) ]
		then
			flag=1
		else
			flag=0		
			echo " ERROR: Result $i is wrong."
			break
		fi
	done
	
	if [ $flag -eq 1 ]
	then
		echo -n " Correct!"
	fi

	echo
done

echo
echo TEST END
echo "##############################"
