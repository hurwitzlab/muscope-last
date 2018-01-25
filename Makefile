PROJECT = muscope
APP = muscope-last
VERSION = 0.0.3
EMAIL = $(CYVERSEUSERNAME)@email.arizona.edu

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.param -o -name launcher_jobfile_\* \) -exec rm {} \;

container:
	rm -f stampede2/$(APP).img
	sudo singularity create --size 1000 stampede2/$(APP).img
	sudo singularity bootstrap stampede2/$(APP).img singularity/$(APP).def
	sudo chown --reference=singularity/$(APP).def stampede2/$(APP).img

iput-container:
	iput -fK stampede2/$(APP).img

iget-container:
	iget -fK $(APP).img
	mv $(APP).img stampede2/
	irm $(APP).img

setup:
	cd setup; sbatch build_contigs_last_db.sh; sbatch build_genes_last_db.sh; sbatch build_proteins_last_db.sh; sbatch build_sqlite_seq_dbs.sh

test:
	cd stampede2; sbatch test.sh

submit-test-job:
	jobs-submit -F stampede2/job.json

submit-test-job-to-public-app:
	jobs-submit -F stampede2/job-public-app.json

files-delete:
	files-delete $(CYVERSEUSERNAME)/applications/$(APP)-$(VERSION)

files-upload:
	files-upload -F stampede2/ $(CYVERSEUSERNAME)/applications/$(APP)-$(VERSION)

apps-addupdate:
	apps-addupdate -F stampede2/app.json

deploy-app: clean files-delete files-upload apps-addupdate

share-app:
	systems-roles-addupdate -v -u <share-with-user> -r USER tacc-stampede2-$(CYVERSEUSERNAME)
	apps-pems-update -v -u <share-with-user> -p READ_EXECUTE $(APP)-$(VERSION)

lytic-rsync-dry-run:
	rsync -n -arvzP --delete --exclude-from=rsync.exclude -e "ssh -A -t hpc ssh -A -t lytic" ./ :project/$(PROJECT)/apps/$(APP)

lytic-rsync:
	rsync -arvzP --delete --exclude-from=rsync.exclude -e "ssh -A -t hpc ssh -A -t lytic" ./ :project/$(PROJECT)/apps/$(APP)

lytic-direct-rsync:
	rsync -arvzP --delete --exclude-from=rsync.exclude -e "ssh -A -t lytic" ./ :project/$(PROJECT)/apps/$(APP)
