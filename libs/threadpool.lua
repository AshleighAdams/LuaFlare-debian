
local threadpool = {}
threadpool._meta = {__index = threadpool}

function threadpool.create(threads, func) expects("number", "function")
	local tp = {}
	tp.queue = {}
	tp.quit = false
	tp.func = func
	tp.routines = {}
	tp.added = 0
	tp.finished = 0
	
	tp.thread_function = function()
		while not tp.quit do
			func(tp:dequeue())
			tp.finished = tp.finished + 1
		end
	end
	
	for i=1, threads do
		table.insert(tp.routines, coroutine.create(tp.thread_function))
	end
	
	return setmetatable(tp, threadpool._meta)
end

function threadpool:enqueue(object) expects(threadpool._meta, "*")
	self.added = self.added + 1
	table.insert(self.queue, object)
end

function threadpool:dequeue() expects(threadpool._meta)
	while not self.quit do
		local obj = self.queue[1]
		if obj ~= nil then
			table.remove(self.queue, 1)
			return obj
		else
			coroutine.yield()
		end
	end
end

function threadpool:done() expects(threadpool._meta)
	return self.added == self.finished
end

function threadpool:step() expects(threadpool._meta)
	for i, co in ipairs(self.routines) do
		if coroutine.status(co) ~= "dead" then -- shouldnt happen
			local suc, err = coroutine.resume(co)
			if not suc then
				warn(err)
			end
		else
			warn("coroutine died")
			table.remove(self.routines, i)
		end
	end
end

return threadpool
