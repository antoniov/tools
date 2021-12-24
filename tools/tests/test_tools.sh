echo "source ~/devel/activate_tools"
source ~/devel/activate_tools

for pkg in clodoo.py cvt_csv_2_rst cvt_csv_2_xml.py cvt_script gen_readme.py inv2draft_n_restore.py list_requirements.py makepo_it.py odoo_dependencies.py odoo_install_repository odoo_shell.py odoo_translation.py please to_pep8.py transodoo.py travis vem wget_odoo_repositories.py; do
    echo "Testing $pkg --version .."
    $pkg -V
    [[ $? -ne 0 ]] && echo "****** TEST $pkg FAILED ******"
done