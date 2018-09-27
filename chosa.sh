#! /bin/bash
	set -x
	#global_config
	project_dir=`sed -n 2p parameters.config | cut -d: -f2`
	branch=`sed -n 2p parameters.config | cut -d: -f1`
	build_tool=`sed -n 2p parameters.config | cut -d: -f3`
	
	log_dir="log"
	shelf_dir="builds_shelf"
	tool_name="ndhCICD"
	#maven_config
	artifact_id=`sed -n 2p maven.config | cut -d: -f1`
	version=`sed -n 2p maven.config | cut -d: -f2`
	packaging=`sed -n 2p maven.config | cut -d: -f3`
	builded_archive=$artifact_id-$version.$packaging
	#tomcat
	tomcat_version=`sed -n 2p maven.config | cut -d: -f4`
	tomcat_webapps="/var/lib/tomcat$tomcat_version/webapps/"
	tomcat_start_point=`sed -n 2p maven.config | cut -d: -f5`
	#git
	git_rep=`sed -n 1p gitrep.config | cut -d= -f2`

	#Workflow
	checkout_to_branch=`cd $project_dir && git checkout $branch`
	local_id=`cd $project_dir && git rev-parse HEAD`
	get_remote_id=`git ls-remote $git_rep refs/heads/$branch`


	remote_id=`echo $get_remote_id | cut -d' ' -f 1`
	#verify whether project dir is available
	if [ ! -d "$project_dir" ] 
	then
		echo "Project Not Found"
		exit 0
	fi
	#verify whether log dir exists
	if [ ! -d "~/$tool_name/$log_dir" ]
        then
		echo `mkdir ~/$tool_name/$log_dir`
	fi
	#verify whether shelf dir exists
        if [ ! -d "~/$tool_name/$shelf_dir" ]
        then
                echo `mkdir ~/$tool_name/$shelf_dir`
        fi


	if [ $remote_id != $local_id ]
	then
		log_info="$(cd $project_dir && git log -1 $branch)"
		echo "Operation starts at : " `date`
		echo $log_info
		echo "******[ we nee to perform pull to $branch ]************"
		echo `(cd $project_dir && git pull)`
		if [ $build_tool = "maven" ]
		then
		
			log_text_maven="$(cd $project_dir && sudo mvn install)"
			build_result="$(cd $project_dir && sudo mvn install | grep -e "BUILD SUCCESS")"
			echo ${build_result}
			############################
			if [[ $build_result = *"[INFO] BUILD SUCCESS"* ]]
			then
        			dateOfBuild=`date --rfc-3339=ns`
				id_hash=( $(openssl rand 100000 | sha1sum) ); printf "%s${r[0]:0:13}\n"
				shelf_name="${dateOfBuild// /#}$id_hash"
				shelf_full_name="$shelf_name.$packaging"
				
				#echo `echo -e "$log_text_maven" > "~/$tool_name/"$shelf_name".log"`
				echo `echo -e "\"$log_text_maven\"" | install -D /dev/stdin "~/$tool_name/"$shelf_name".log"`
				
				echo "$(sudo cp $project_dir/target/$builded_archive ~/$tool_name/$shelf_dir/$shelf_full_name)"

				echo "$(sudo cp $project_dir/target/$builded_archive $tomcat_webapps$tomcat_start_point.$packaging)"

			else
        			echo "BUILD FAILED"
				echo `echo -e "\"$log_text_maven\"" | install -D /dev/stdin "~/$tool_name/"$shelf_name".log"`

			fi
			############################
		else	
			echo "#ERR: Not supported yet"
		fi
		echo "ENDED AT :" `date`
		echo "####################################"
	fi

