import os
c.NotebookApp.ip = '*'
c.NotebookApp.allow_remote_access = True
c.MultiKernelManager.kernel_manager_class = 'lc_wrapper.LCWrapperKernelManager'
c.KernelManager.shutdown_wait_time = 10.0
c.FileContentsManager.delete_to_trash = False
c.NotebookApp.quit_button = False

if 'PASSWORD' in os.environ:
    from notebook.auth import passwd
    c.NotebookApp.password = passwd(os.environ['PASSWORD'])
    del os.environ['PASSWORD']

ipython_startup = os.path.expanduser('~/.ipython/profile_default/startup/'
                                     '10-custom-get_ipython_system.py')
if not os.path.exists(ipython_startup):
    import shutil
    parent, _ = os.path.split(ipython_startup)
    if not os.path.exists(parent):
        os.makedirs(parent)
    shutil.copy('/etc/ipython/profile_default/startup/'
                '10-custom-get_ipython_system.py',
                ipython_startup)
