<?php

	namespace User\Auth;

	class Model implements \Core\Auth\Model
	{
		public function get ($params)
		{
			$query = Database::get()->prepare("
				SELECT
				`id`,
				`login`,
				`password`
				FROM `users`
				WHERE ".$this->where($by));

			$this->bind($query, $params);

			if ($query->execute())
			{
				if ($row = $query->fetch())
				{
					new \App\User($row);
				}
			}
		}
		public function where ($params, $operator='AND')
		{
			if (is_array($params))
			{
				foreach ($params as $name => $value)
				{
					if (is_array($value))
					{
						$result .= "(".$this->where($value,"OR").") ".$operator;
					}
					else
					{
						$result .=
					}
				}
			}
		}
		public function bind ($query, $params)
		{

		}
	}

	$method->get ([
		['login'=>$login,'email'=>$login],
		'password'=>$password
	]);