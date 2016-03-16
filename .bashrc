# .bashrc                                                                                                     
                                                                                                              
# Source global definitions                                                                                   
if [ -f /etc/bashrc ]; then                                                                                   
    . /etc/bashrc                                                                                             
fi                                                                                                            
                                                                                                              
# User specific aliases and functions                                                                         
                                                                                                              
sharedir=/nfs/users/zhaozhan                                                                                  
if [ -d $sharedir/tmp ];then                                                                                  
        #echo "bej301159 has been mounted"                                                                    
        dumya=1                                                                                               
else                                                                                                          
        mkdir -p $sharedir                                                                                    
        sudo /sbin/mount.cifs //bej301159/share/${sharedir} $sharedir -o user=zhaozhan,pass=welcome2oracle    
        #echo "bej301159 mounted"                                                                             
fi                                                                                                            
                                                                                                              
if [[ -d $sharedir ]]; then                                                                                   
    [[ ! -f ~/.tmux.conf ]] && ln -sf $sharedir/.tmux.conf ~/                                                 
    [[ ! -d ~/.vim ]] && ln -sf $sharedir/.vim ~/                                                             
    [[ ! -f ~/.vimrc ]] && ln -sf $sharedir/.vimrc ~/                                                         
    [[ ! -d ~/.dir_colors ]] && ln -sf $sharedir/.dir_colors ~/                                               
    . $sharedir/.bashrc                                                                                       
fi                                                                                                            
