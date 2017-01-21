This is the public part of my ``.bashrc`` file.
The rest of it is not very interesting.

See `bashrc-public.sh`_.

.. _bashrc-public.sh: ./bashrc-public.sh

If you want to add this to your bash configuration,
download the git repository wherever you like::

    git clone https://github.com/nbeaver/bashrc-public.git

then source it in your ``.bashrc``::

    echo "source $PWD/bashrc-public.sh" >> ~/.bashrc

But please be cognizant of the risks of adding untrusted code to your shell configuration.

-------
License
-------

This project is licensed under the terms of the `MIT license`_.

.. _MIT license: LICENSE.txt
