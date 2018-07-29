bzcat scheduling_preliminary_app_interference_20180606.csv.bz2 |\
	awk -F"," '{
			    printf("<BASE#rule-%s_%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <BASE#Rule>\n" ,$1,$2);\
                printf("<BASE#rule-%s_%s> <BASE#A> <BASE#%s>\n" ,$1 ,$2, $1);\
			    printf("<BASE#rule-%s_%s> <BASE#B> <BASE#%s>\n" ,$1,$2,$2);\
				printf("<BASE#rule-%s_%s> <BASE#X> \"%s\"^^<XML#integer>\n" ,$1,$2,$3)}' |  \
sed 's/BASE/http:\/\/tianchi.com\/machinedispatch/g;s/XML/http:\/\/www.w3.org\/2001\/XMLSchema/g' |awk '!a[$0]++'| /home/asenal/BIN/agraph-6.4.1/bin/agload diaodu -i nt  -e ignore - 


bzcat scheduling_preliminary_app_resources_20180606.csv.bz2  |\
	awk -F"," '{app=$1;split($2,cpu,"|");split($3,memory,"|");P=$4;M=$5;PM=$6;\
   			    for(i=1;i<=96;i++){ \
			    printf("<BASE#request-%s-%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <BASE#Request>\n" ,app,i);\
			  	printf("<BASE#request-%s-%s> <BASE#consumer> <BASE#%s>\n" ,app,i,app);\
				printf("<BASE#request-%s-%s> <BASE#timeslot> \"%s\"^^<XML#integer>\n" ,app,i,i);\
				printf("<BASE#request-%s-%s> <BASE#cpu> \"%s\"^^<XML#float>\n" ,app,i,cpu[i]);\
				printf("<BASE#request-%s-%s> <BASE#memory> \"%s\"^^<XML#float>\n" ,app,i,memory[i]);\

				printf("<BASE#request-%s-%s> <BASE#P> \"%s\"^^<XML#float>\n" ,app,i,P);\
				printf("<BASE#request-%s-%s> <BASE#M> \"%s\"^^<XML#float>\n" ,app,i,M);\
				printf("<BASE#request-%s-%s> <BASE#PM> \"%s\"^^<XML#float>\n" ,app,i,PM);\
				}}' |\
				sed 's/BASE/http:\/\/tianchi.com\/machinedispatch/g;s/XML/http:\/\/www.w3.org\/2001\/XMLSchema/g' |awk '!a[$0]++'| /home/asenal/BIN/agraph-6.4.1/bin/agload diaodu -i nt  -e ignore -


bzcat scheduling_preliminary_machine_resources_20180606.csv.bz2 |\
	awk -F"," '{machine=$1;cpu=$2;memory=$3;disk=$4;P=$5;M=$6;PM=$7;\
			   printf("<BASE#%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <BASE#Machine>\n" ,machine);\
			   printf("<BASE#%s> <BASE#cpu> \"%s\"^^<XML#float>\n" ,machine,cpu);\
			   printf("<BASE#%s> <BASE#memory> \"%s\"^^<XML#float>\n" ,machine,memory);\
			   printf("<BASE#%s> <BASE#P> \"%s\"^^<XML#integer>\n" ,machine,P);\
			   printf("<BASE#%s> <BASE#M> \"%s\"^^<XML#integer>\n" ,machine,M);\
			   printf("<BASE#%s> <BASE#PM> \"%s\"^^<XML#integer>\n" ,machine,PM);\
			   printf("<BASE#%s> <BASE#disk> \"%s\"^^<XML#float>\n" ,machine,disk);}'  |\
	sed 's/BASE/http:\/\/tianchi.com\/machinedispatch/g;s/XML/http:\/\/www.w3.org\/2001\/XMLSchema/g' | awk '!a[$0]++'| /home/asenal/BIN/agraph-6.4.1/bin/agload diaodu -i nt  -e ignore -


bzcat scheduling_preliminary_instance_deploy_20180606.csv.bz2 |
	awk -F"," '{instance=$1;app=$2;machine=$3;\
			    printf("<BASE#%s> <BASE#deployTo> <BASE#%s>\n" ,app,instance);
			    printf("<BASE#%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <BASE#Instance>\n" ,instance);
			    printf("<BASE#%s> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <BASE#App>\n" ,app);
				if(length($3)>0){
			  	  printf("<BASE#%s> <BASE#runningOn> <BASE#%s>\n" ,instance,machine);\
				}}' |\
sed 's/BASE/http:\/\/tianchi.com\/machinedispatch/g;s/XML/http:\/\/www.w3.org\/2001\/XMLSchema/g' |awk '!a[$0]++'| /home/asenal/BIN/agraph-6.4.1/bin/agload diaodu -i nt  -e ignore - 
