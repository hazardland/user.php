<?php

	namespace User\Auth;

	class Method implements \Core\Auth\Method
	{
		public function getName()
		{
			return 'basic';
		}
		public function login ($username, $password)
		{

		}
		public function logout()
		{

		}
	}
