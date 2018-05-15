PROJECT = muscope
APP = muscope-last
VERSION = 0.0.4
EMAIL = $(CYVERSEUSERNAME)@email.arizona.edu

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.param -o -name launcher_jobfile_\* \) -exec rm {} \;

container:
	rm -f stampede2/$(APP).img
	sudo singularity create --size 1000 singularity/$(APP)-$(VERSION).img
	sudo singularity bootstrap singularity/$(APP)-$(VERSION).img singularity/$(APP).def
	sudo chown --reference=singularity/$(APP).def singularity/$(APP)-$(VERSION).img

iput-container:
	iput -fK singularity/$(APP)-$(VERSION).img

iget-container:
	cd /work/05066/imicrobe/singularity/; iget -fK $(APP)-$(VERSION).img; chmod ag+r $(APP)-$(VERSION).img
	irm $(APP)-$(VERSION).img

setup:
	cd setup; sbatch build_contigs_last_db.sh
	cd setup; sbatch build_genes_last_db.sh
	cd setup; sbatch build_proteins_last_db.sh
	cd setup; sbatch build_sqlite_seq_dbs.sh
	cd setup; sbatch build_test_contigs_genes_proteins_last_db.sh

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
